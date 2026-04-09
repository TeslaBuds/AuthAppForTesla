//
//  AuthViewModel.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import Foundation
import os

private let aftOAuthLogger = Logger(subsystem: "dk.kimhansen.AuthAppForTesla", category: "oauth")
import CryptoKit

actor AuthController {
    public static let shared = AuthController()

    private init() {
        // Private initializer, so no accidental class instantiations outside singleton can happen
    }

    /// Mirror an OAuth diagnostic line to both os.Logger (so a developer
    /// running the app under Console.app can see it) and to LiveTestLog
    /// (so the live UI test can read it back via accessibility on a
    /// hidden Text view in the root view).
    private nonisolated func logOAuth(_ message: String) {
        #if DEBUG
        aftOAuthLogger.notice("[AFT-OAUTH] \(message)")
        LiveTestLog.shared.append(message)
        #endif
    }


    public func logOut(environment: LoginEnvironment) async
    {
        // Delete the active profile (and its mirrored legacy entry).
        let collection = await TokenProfileStore.shared.load(environment: environment)
        if let active = collection.activeProfile {
            await TokenProfileStore.shared.delete(id: active.id, environment: environment)
        } else {
            // Fallback: clean any stale legacy keychain entry directly.
            switch environment {
            case .owner:
                KeychainWrapper.global.removeObject(forKey: kTokenV3, withAccessibility: .afterFirstUnlock)
            case .fleet:
                KeychainWrapper.global.removeObject(forKey: kTokenV4, withAccessibility: .afterFirstUnlock)
            }
        }
    }

    func setJwtToken(_ token: Token) async
    {
        // Persist via the profile store so the active profile + legacy
        // keychain mirror are updated together.
        await TokenProfileStore.shared.updateActiveToken(token, environment: .owner)
    }

    // MARK: - Profile management

    func loadProfiles(environment: LoginEnvironment) async -> TokenProfileCollection {
        await TokenProfileStore.shared.load(environment: environment)
    }

    func setActiveProfile(id: UUID, environment: LoginEnvironment) async {
        await TokenProfileStore.shared.setActive(id: id, environment: environment)
    }

    func renameProfile(id: UUID, to name: String, environment: LoginEnvironment) async {
        await TokenProfileStore.shared.rename(id: id, to: name, environment: environment)
    }

    func deleteProfile(id: UUID, environment: LoginEnvironment) async {
        await TokenProfileStore.shared.delete(id: id, environment: environment)
    }

    func addProfile(name: String, token: Token, environment: LoginEnvironment, makeActive: Bool = true) async {
        let profile = TokenProfile(name: name, token: token)
        await TokenProfileStore.shared.upsert(profile: profile, environment: environment, makeActive: makeActive)
    }

    func suggestedProfileName(environment: LoginEnvironment) async -> String {
        await TokenProfileStore.shared.suggestedName(for: environment)
    }

    /// Removes every Owners and Fleet token profile, plus any legacy
    /// single-token keychain entries. Used by the live UI test harness
    /// so each test starts from a guaranteed clean keychain — never
    /// invoked from production code paths.
    func wipeAllProfiles() async {
        for env in [LoginEnvironment.owner, LoginEnvironment.fleet] {
            let collection = await TokenProfileStore.shared.load(environment: env)
            for profile in collection.profiles {
                await TokenProfileStore.shared.delete(id: profile.id, environment: env)
            }
        }
        // Belt and braces — clear any legacy mirror entries the store
        // didn't already wipe (e.g. from a build that pre-dated profile
        // storage entirely).
        KeychainWrapper.global.removeObject(forKey: kTokenV3, withAccessibility: .afterFirstUnlock)
        KeychainWrapper.global.removeObject(forKey: kTokenV4, withAccessibility: .afterFirstUnlock)
    }
    
    var v3Token: Token? {
        var token: Token?
        if let tokenJson = getV3Token() { token = try? JSONDecoder().decode(Token.self, from: tokenJson) }
        
        return token
    }

    func getV3Token() -> Data? {
        if let tokenJson = KeychainWrapper.global.data(forKey: kTokenV3, withAccessibility: .afterFirstUnlock)
        {
            if (try? JSONDecoder().decode(Token.self, from: tokenJson)) != nil
            {
                return tokenJson
            }
        }
        return nil
    }
    
    func acquireTokenV3Silent(forceRefresh: Bool = false) async -> Token? {
        var token: Token?
        if let tokenJson = getV3Token() {
            token = try? JSONDecoder().decode(Token.self, from: tokenJson)
        }

        if let token
        {
            if (forceRefresh || token.expires_at ?? Date() <= Date().addingTimeInterval(60))
            {
                let refreshedToken = await oauthRenew(token.refresh_token, token.region ?? .global)
                if let refreshedToken {
                    await TokenProfileStore.shared.updateActiveToken(refreshedToken, environment: .owner)
                } else {
                    return nil
                }
                return refreshedToken
            }
            return token
        }
        return nil
    }
   
    func getAuthByRegion(region: TokenRegion) -> String {
        switch region {
        case .global:
            "https://auth.tesla.com"
        case .china:
            "https://auth.tesla.cn"
        }
    }
    
    
    func oauthRenew(_ refreshToken: String, _ region: TokenRegion, retries: Int = 0) async -> Token? {
        let url = getAuthByRegion(region: region)
        
        let result = await NetworkController.shared.post("\(url)/oauth2/v3/token", parameters:
                                                            ["grant_type": "refresh_token",
                                                             "scope": "openid email offline_access",
                                                             "client_id": "ownerapi",
                                                             "refresh_token": "\(refreshToken)"])
        switch result {
        case let .success(result):
            var token: Token?
            if let expiresIn = result.dictionaryBody["expires_in"] as? Int,
               let access_token = result.dictionaryBody["access_token"] as? String,
               let token_type = result.dictionaryBody["token_type"] as? String,
               let refresh_token = result.dictionaryBody["refresh_token"] as? String {
                let expiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))
                
                token = Token(access_token: access_token, token_type: token_type, expires_in: expiresIn, refresh_token: refresh_token, expires_at: expiresAt, region: region)
                if let token {
                    await TokenProfileStore.shared.updateActiveToken(token, environment: .owner)
                }
            }
            return token
        case let .failure(error):
            if error.statusCode == 400 {
                if retries < 3 {
                    return await oauthRenew(refreshToken, region, retries: retries + 1)
                }
                KeychainWrapper.global.removeObject(forKey: kTokenV3, withAccessibility: .afterFirstUnlock)
            } else if error.statusCode == 401 {
                if retries < 3 {
                    return await oauthRenew(refreshToken, region, retries: retries + 1)
                }
                KeychainWrapper.global.removeObject(forKey: kTokenV3, withAccessibility: .afterFirstUnlock)
            } else if error.statusCode == 848 {
                // Mystical SSL error
                if retries < 3 {
                    return await oauthRenew(refreshToken, region, retries: retries + 1)
                }
            } else {
                // 19 - network connection was lost
                // 23 - request timed out
                
                if retries < 3 {
                    return await oauthRenew(refreshToken, region, retries: retries + 1)
                }
            }
            return nil
        }
    }

    /// Builds the OAuth authorization URL for V3 (Owners API) login.
    /// Returns the URL and code verifier needed to complete the exchange.
    func buildOAuthURLV3(region: TokenRegion, redirectUrl: String) -> (url: URL, codeVerifier: String)? {
        let authenticateUrl = getAuthByRegion(region: region)
        let codeRequest = AuthCodeRequest()

        var urlComponents = URLComponents(string: authenticateUrl)
        urlComponents?.path = "/oauth2/v3/authorize"
        urlComponents?.queryItems = codeRequest.parameters()

        guard let safeUrlComponents = urlComponents, let url = safeUrlComponents.url else {
            return nil
        }

        return (url, codeRequest.codeVerifier)
    }

    /// Exchanges an OAuth authorization code for a V3 token. When
    /// `addAsNewProfile` is true, the resulting token is stored in a new
    /// profile (using the suggested name) instead of replacing the active
    /// profile's token.
    func exchangeCodeV3(_ code: String, codeVerifier: String, region: TokenRegion, addAsNewProfile: Bool = false) async -> Token? {
        await oauthCodeV3(code, codeVerifier, region, addAsNewProfile: addAsNewProfile)
    }

    fileprivate func oauthCodeV3(_ code: String, _ codeVerifier: String, _ region: TokenRegion, addAsNewProfile: Bool = false, retries: Int = 0) async -> Token? {
        let url = getAuthByRegion(region: region)
        logOAuth("oauthCodeV3 attempt \(retries + 1): POST \(url)/oauth2/v3/token code=\(String(code.prefix(20)))… verifier=\(String(codeVerifier.prefix(10)))…")
        let result = await NetworkController.shared.post("\(url)/oauth2/v3/token", parameters:
                                        ["grant_type": "authorization_code",
                                         "client_id": "ownerapi",
                                         "code": code,
                                         "redirect_uri": "tesla://auth/callback",
                                         "code_verifier": codeVerifier,
                                         "scope": "openid email offline_access phone"])
        switch result {
        case let .success(result):
            logOAuth("oauthCodeV3 200 OK, body keys: \(Array(result.dictionaryBody.keys))")
            if let body = String(data: result.data, encoding: .utf8) {
                logOAuth("oauthCodeV3 body: \(String(body.prefix(500)))")
            }
            var token: Token?
            if let expiresIn = result.dictionaryBody["expires_in"] as? Int,
               let access_token = result.dictionaryBody["access_token"] as? String,
               let token_type = result.dictionaryBody["token_type"] as? String,
               let refresh_token = result.dictionaryBody["refresh_token"] as? String {
                let expiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))
                
                token = Token(access_token: access_token, token_type: token_type, expires_in: expiresIn, refresh_token: refresh_token, expires_at: expiresAt, region: region)
                if let token {
                    if addAsNewProfile {
                        let name = await TokenProfileStore.shared.suggestedName(for: .owner)
                        let profile = TokenProfile(name: name, token: token)
                        await TokenProfileStore.shared.upsert(profile: profile, environment: .owner, makeActive: true)
                    } else {
                        await TokenProfileStore.shared.updateActiveToken(token, environment: .owner)
                    }
                }
            } else {
                logOAuth("oauthCodeV3 200 OK but missing one of expires_in/access_token/token_type/refresh_token")
            }
            return token
        case .failure(let error):
            logOAuth("oauthCodeV3 FAIL status=\(error.statusCode) error=\(error.error)")
            if let body = String(data: error.data, encoding: .utf8) {
                logOAuth("oauthCodeV3 fail body: \(String(body.prefix(500)))")
            }
            if error.statusCode == 400 {
                if retries < 3 {
                    return await oauthCodeV3(code, codeVerifier, region, addAsNewProfile: addAsNewProfile, retries: retries + 1)
                }
                KeychainWrapper.global.removeObject(forKey: kTokenV3, withAccessibility: .afterFirstUnlock)
            } else if error.statusCode == 401 {
                if retries < 3 {
                    return await oauthCodeV3(code, codeVerifier, region, addAsNewProfile: addAsNewProfile, retries: retries + 1)
                }
                KeychainWrapper.global.removeObject(forKey: kTokenV3, withAccessibility: .afterFirstUnlock)
            } else if error.statusCode == 848 {
                // Mystical SSL error
                if retries < 3 {
                    return await oauthCodeV3(code, codeVerifier, region, addAsNewProfile: addAsNewProfile, retries: retries + 1)
                }
            } else {
                // 19 - network connection was lost
                // 23 - request timed out
                if retries < 3 {
                    return await oauthCodeV3(code, codeVerifier, region, addAsNewProfile: addAsNewProfile, retries: retries + 1)
                }

            }
            return nil
        }
    }
    
    class AuthCodeRequest: Encodable {
        var responseType: String = "code"
        var clientID = "ownerapi"
        var clientSecret = kTeslaSecret
        var redirectURI = kTeslaRedirectUri
        var scope = "openid email offline_access phone"
        let codeVerifier: String
        let codeChallenge: String
        var codeChallengeMethod = "S256"
        var state = "AuthAppForTesla"
        var isInApp = "true"
        var prompt = "login"

        init() {
            codeVerifier = "".codeVerifier
            codeChallenge = codeVerifier.challenge
        }

        // MARK: Codable protocol

        enum CodingKeys: String, CodingKey {
            typealias RawValue = String

            case clientID = "client_id"
            case redirectURI = "redirect_uri"
            case responseType = "response_type"
            case scope
            case codeChallenge = "code_challenge"
            case codeChallengeMethod = "code_challenge_method"
            case state
            case isInApp = "is_in_app"
            case prompt
        }

        func parameters() -> [URLQueryItem] {
            [
                URLQueryItem(name: CodingKeys.clientID.rawValue, value: clientID),
                URLQueryItem(name: CodingKeys.redirectURI.rawValue, value: redirectURI),
                URLQueryItem(name: CodingKeys.responseType.rawValue, value: responseType),
                URLQueryItem(name: CodingKeys.scope.rawValue, value: scope),
                URLQueryItem(name: CodingKeys.codeChallenge.rawValue, value: codeChallenge),
                URLQueryItem(name: CodingKeys.codeChallengeMethod.rawValue, value: codeChallengeMethod),
                URLQueryItem(name: CodingKeys.state.rawValue, value: state),
                URLQueryItem(name: CodingKeys.isInApp.rawValue, value: isInApp),
                URLQueryItem(name: CodingKeys.prompt.rawValue, value: prompt)
            ]
        }
    }
}

extension String {
    var codeVerifier: String {
        let verifier = "\(Date.now.ISO8601Format())\(Date.now.ISO8601Format())\(Date.now.ISO8601Format())"
            .data(using: .utf8)!.base64EncodedString()
            .replacing("+", with: "-")
            .replacing("/", with: "_")
            .replacing("=", with: "")
            .trimmingCharacters(in: .whitespaces)
            .prefix(43)
        return String(verifier)
    }

    var challenge: String {
        let data = Data(utf8)
        let hash = SHA256.hash(data: data)
        let base64 = Data(hash).base64EncodedString()
        return base64
            .replacing("+", with: "-")
            .replacing("/", with: "_")
            .replacing("=", with: "")
    }
}
