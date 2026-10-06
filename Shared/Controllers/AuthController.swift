//
//  AuthViewModel.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import Foundation
import TeslaAuthKit
import os

private let aftOAuthLogger = Logger(subsystem: "dk.kimhansen.AuthAppForTesla", category: "oauth")
import CryptoKit

actor AuthController {
    public static let shared = AuthController()

    /// Every token refresh goes through this: single flight per profile,
    /// rotation-race aware, and never deletes a stored profile (#49, #50).
    let refreshService = TokenRefreshService(
        store: .shared,
        transport: TeslaTokenEndpoint(),
        ledger: UserDefaultsRejectionLedger()
    )

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


    /// Signs out of the active profile: deletes it (and its mirrored
    /// legacy entry). Only ever called because the person asked to sign
    /// out — never from a refresh or a sign-in path (#49, #50).
    public func logOut(environment: LoginEnvironment) async
    {
        // Delete the active profile (and its mirrored legacy entry).
        let collection = await TokenProfileStore.shared.load(environment: environment)
        if let active = collection.activeProfile {
            _ = try? await TokenProfileStore.shared.delete(id: active.id, environment: environment)
        } else {
            // Fallback: clean any stale legacy keychain entry — through
            // the store, which refuses when the synced items are unreadable.
            try? await TokenProfileStore.shared.clearLegacyMirror(environment: environment)
        }
    }

    func setJwtToken(_ token: Token) async
    {
        // Persist via the profile store so the active profile + legacy
        // keychain mirror are updated together.
        _ = try? await TokenProfileStore.shared.updateActiveToken(token, environment: .owner)
    }

    // MARK: - Profile management

    func loadProfiles(environment: LoginEnvironment) async -> TokenProfileCollection {
        await TokenProfileStore.shared.load(environment: environment)
    }

    /// The stored profiles, telling an unreadable store apart from an
    /// empty one (the sync-wipe guard, #44).
    func loadProfileState(environment: LoginEnvironment) async -> TokenProfileLoadState {
        await TokenProfileStore.shared.loadState(environment: environment)
    }

    func setActiveProfile(id: UUID, environment: LoginEnvironment) async throws(TokenStoreError) {
        try await TokenProfileStore.shared.setActive(id: id, environment: environment)
    }

    func renameProfile(id: UUID, to name: String, environment: LoginEnvironment) async throws(TokenStoreError) {
        try await TokenProfileStore.shared.rename(id: id, to: name, environment: environment)
    }

    func deleteProfile(id: UUID, environment: LoginEnvironment) async throws(TokenStoreError) {
        try await TokenProfileStore.shared.delete(id: id, environment: environment)
    }

    func addProfile(name: String, token: Token, environment: LoginEnvironment, makeActive: Bool = true) async throws(TokenStoreError) {
        let profile = TokenProfile(name: name, token: token)
        try await TokenProfileStore.shared.upsert(profile: profile, environment: environment, makeActive: makeActive)
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
                _ = try? await TokenProfileStore.shared.delete(id: profile.id, environment: env)
            }
            // Belt and braces — clear any legacy mirror entry the store
            // didn't already wipe (e.g. from a build that pre-dated profile
            // storage entirely).
            try? await TokenProfileStore.shared.clearLegacyMirror(environment: env)
        }
    }
    
    /// The active Owners profile's token: from the profile store, or the
    /// legacy single-token mirror when there is no profile list.
    var v3Token: Token? {
        get async { await activeToken(environment: .owner) }
    }

    /// The active profile's stored token for an API.
    func activeToken(environment: LoginEnvironment) async -> Token? {
        if let token = await TokenProfileStore.shared.load(environment: environment).activeProfile?.token {
            return token
        }
        let data = environment == .owner ? getV3Token() : getV4Token()
        return data.flatMap { try? JSONDecoder().decode(Token.self, from: $0) }
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

    /// Refreshes the active profile's token, reporting why when it could
    /// not: offline and refused both keep the stored token (#49, #50).
    func refreshActive(environment: LoginEnvironment, forceRefresh: Bool) async -> TokenRefreshOutcome {
        await refreshService.refresh(environment: environment, forceRefresh: forceRefresh)
    }

    /// The active Owners token, refreshed when forced or due; nil when a
    /// needed refresh failed.
    func acquireTokenV3Silent(forceRefresh: Bool = false) async -> Token? {
        await refreshService.refresh(environment: .owner, forceRefresh: forceRefresh).freshToken
    }

    func getAuthByRegion(region: TokenRegion) -> String {
        switch region {
        case .global:
            "https://auth.tesla.com"
        case .china:
            "https://auth.tesla.cn"
        }
    }

    /// Returns the V3 (Owners API) token for a specific profile,
    /// refreshing if it's expired or about to expire. Does NOT change
    /// the active profile — used exclusively by the App Intent path
    /// when the user has explicitly chosen an account in their Shortcut.
    func acquireTokenV3Silent(profileId: UUID, forceRefresh: Bool = false) async -> Token? {
        await refreshService.refresh(environment: .owner, profileId: profileId, forceRefresh: forceRefresh).freshToken
    }

    /// Builds the OAuth authorization URL for V3 (Owners API) login.
    /// Returns the URL, plus the code verifier and `state` the redirect
    /// must be checked against and the exchange must send (#51).
    func buildOAuthURLV3(region: TokenRegion, redirectUrl: String) -> (url: URL, codeVerifier: String, state: String)? {
        let authenticateUrl = getAuthByRegion(region: region)
        let codeRequest = AuthCodeRequest()

        var urlComponents = URLComponents(string: authenticateUrl)
        urlComponents?.path = "/oauth2/v3/authorize"
        urlComponents?.queryItems = codeRequest.parameters()

        guard let safeUrlComponents = urlComponents, let url = safeUrlComponents.url else {
            return nil
        }

        return (url, codeRequest.codeVerifier, codeRequest.state)
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
                        _ = try? await TokenProfileStore.shared.upsert(profile: profile, environment: .owner, makeActive: true)
                    } else {
                        _ = try? await TokenProfileStore.shared.updateActiveToken(token, environment: .owner)
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
            // An authorization code is single-use: a 4xx answer is final.
            // Only a lost connection or a server error is worth retrying.
            // A failed sign-in never touches the stored tokens (#49).
            if Self.isRetryable(error), retries < 3 {
                return await oauthCodeV3(code, codeVerifier, region, addAsNewProfile: addAsNewProfile, retries: retries + 1)
            }
            return nil
        }
    }

    /// No HTTP answer at all, or a 5xx: worth another try.
    static func isRetryable(_ failure: FailureDataResponse) -> Bool {
        failure.fullResponse == nil || failure.statusCode >= 500
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
        /// Random per flow, and checked on the redirect (#51).
        let state: String
        var isInApp = "true"
        var prompt = "login"

        init() {
            codeVerifier = PKCE.makeCodeVerifier()
            codeChallenge = codeVerifier.challenge
            state = PKCE.makeState()
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
