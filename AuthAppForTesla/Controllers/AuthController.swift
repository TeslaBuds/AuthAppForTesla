//
//  AuthViewModel.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import Foundation
import CryptoKit

class AuthController {
    private static var sharedAuthController: AuthController = {
        let authController = AuthController()
        return authController
    }()
    
    class func shared() -> AuthController {
        return sharedAuthController
    }
    
    public func logOut(environment: LoginEnvironment)
    {
        switch environment {
        case .owner:
            KeychainWrapper.global.removeObject(forKey: kTokenV3, withAccessibility: .afterFirstUnlock)
        case .fleet:
            KeychainWrapper.global.removeObject(forKey: kTokenV4, withAccessibility: .afterFirstUnlock)
            KeychainWrapper.global.removeObject(forKey: kFleetClientID, withAccessibility: .afterFirstUnlock)
            KeychainWrapper.global.removeObject(forKey: kFleetClientSecret, withAccessibility: .afterFirstUnlock)
            KeychainWrapper.global.removeObject(forKey: kFleetRedirectUri, withAccessibility: .afterFirstUnlock)
        }
//        KeychainWrapper.global.removeAllKeys()
    }
    
    func setJwtToken(_ token: Token)
    {
        if let encodedToken = try? JSONEncoder().encode(token) {
            KeychainWrapper.global.set(encodedToken, forKey: kTokenV3, withAccessibility: .afterFirstUnlock)
        }
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
    
    func acquireTokenV3Silent(forceRefresh: Bool = false, _ completion: @escaping (Token?) -> ()) {
        var token: Token?
        if let tokenJson = getV3Token()
        { token = try? JSONDecoder().decode(Token.self, from: tokenJson) }
        
        if let token = token
        {
            if (forceRefresh || token.expires_at ?? Date() <= Date().addingTimeInterval(60))
            {
                oauthRenew(token.refresh_token, token.region ?? .global) { (refreshedToken) in
                    if let refreshedToken = refreshedToken, let encodedToken = try? JSONEncoder().encode(refreshedToken)
                    {
                        KeychainWrapper.global.set(encodedToken, forKey: kTokenV3, withAccessibility: .afterFirstUnlock)
                    }
                    else
                    {
                        completion(nil)
                        return
                    }
                    completion(refreshedToken)
                }
                return
            }
            completion(token)
            return
        }
        completion(nil)
    }
    
    func getAuthByRegion(region: TokenRegion) -> String {
        switch region {
        case .global:
            "https://auth.tesla.com"
        case .china:
            "https://auth.tesla.cn"
        }
    }
    
    fileprivate func oauthRenew(_ refreshToken: String, _ region: TokenRegion, retries: Int = 0, _ completion: @escaping (Token?) -> ()) {
        let url = getAuthByRegion(region: region)
        
        NetworkController.shared.post("\(url)/oauth2/v3/token", parameters:
                                        ["grant_type": "refresh_token",
                                         "scope": "openid email offline_access",
                                         "client_id": "ownerapi",
                                         "client_secret": kTeslaSecret,
                                         "refresh_token": "\(refreshToken)"]) { result in
            switch result {
            case let .success(result):
                var token: Token?
                if let expiresIn = result.dictionaryBody["expires_in"] as? Int,
                   let access_token = result.dictionaryBody["access_token"] as? String,
                   let token_type = result.dictionaryBody["token_type"] as? String,
                   let refresh_token = result.dictionaryBody["refresh_token"] as? String {
                    let expiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))
                    
                    token = Token(access_token: access_token, token_type: token_type, expires_in: expiresIn, refresh_token: refresh_token, expires_at: expiresAt, region: region)
                    if let encodedToken = try? JSONEncoder().encode(token) {
                        KeychainWrapper.global.set(encodedToken, forKey: kTokenV3, withAccessibility: .afterFirstUnlock)
                    }
                    if refreshToken != refresh_token {
                    }
                }
                completion(token)
                return
            case let .failure(error):
                if error.statusCode == 400 {
                    if retries < 3 {
                        self.oauthRenew(refreshToken, region, retries: retries + 1, completion)
                        return
                    }
                    KeychainWrapper.global.removeObject(forKey: kTokenV3, withAccessibility: .afterFirstUnlock)
                } else if error.statusCode == 401 {
                    if retries < 3 {
                        self.oauthRenew(refreshToken, region, retries: retries + 1, completion)
                        return
                    }
                    KeychainWrapper.global.removeObject(forKey: kTokenV3, withAccessibility: .afterFirstUnlock)
                } else if error.statusCode == 848 {
                    // Mystical SSL error
                    if retries < 3 {
                        self.oauthRenew(refreshToken, region, retries: retries + 1, completion)
                        return
                    }
                } else {
                    // 19 - network connection was lost
                    // 23 - request timed out
                    
                    if retries < 3 {
                        self.oauthRenew(refreshToken, region, retries: retries + 1, completion)
                        return
                    }
                    // set offline - not logged out
                }
                completion(nil)
            }
        }
    }
    
    public func authenticateWeb(region: TokenRegion, redirectUrl: String, completion: @escaping (Result<Token, Error>) -> Void) -> AuthWebViewController? {
        let authenticateUrl = getAuthByRegion(region: region)
        let codeRequest = AuthCodeRequest()
        
        var urlComponents = URLComponents(string: authenticateUrl)
        urlComponents?.path = "/oauth2/v3/authorize"
        urlComponents?.queryItems = codeRequest.parameters()
        
        guard let safeUrlComponents = urlComponents else {
            completion(Result.failure(TeslaError.authenticationFailed))
            return nil
        }
        
        let teslaWebLoginViewController = AuthWebViewController(url: safeUrlComponents.url!, redirectUrl: redirectUrl)
        
        teslaWebLoginViewController.result = { result in
            switch result {
            case let .success(url):
                let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
                if let queryItems = urlComponents?.queryItems {
                    for queryItem in queryItems {
                        if queryItem.name == "code", let code = queryItem.value {
                            self.oauthCode(code, codeRequest.codeVerifier, region) { token in
                                if let token {
                                    completion(.success(token))
                                } else {
                                    completion(.failure(TeslaError.authenticationFailed))
                                }
                            }
                            return
                        }
                    }
                }
                completion(Result.failure(TeslaError.authenticationFailed))
            case let .failure(error):
                completion(Result.failure(error))
            }
        }
        
        return teslaWebLoginViewController
    }
    
    fileprivate func oauthCode(_ code: String, _ codeVerifier: String, _ region: TokenRegion, retries: Int = 0, _ completion: @escaping (Token?) -> Void) {
        let url = getAuthByRegion(region: region)
        
        NetworkController.shared.post("\(url)/oauth2/v3/token", parameters:
                                        ["grant_type": "authorization_code",
                                         "client_id": "ownerapi",
                                         "client_secret": kTeslaSecret,
                                         "code": code,
                                         "redirect_uri": "tesla://auth/callback",
                                         "code_verifier": codeVerifier,
                                         "scope": "openid email offline_access phone"]) { result in
            switch result {
            case let .success(result):
                var token: Token?
                if let expiresIn = result.dictionaryBody["expires_in"] as? Int,
                   let access_token = result.dictionaryBody["access_token"] as? String,
                   let token_type = result.dictionaryBody["token_type"] as? String,
                   let refresh_token = result.dictionaryBody["refresh_token"] as? String {
                    let expiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))
                    
                    token = Token(access_token: access_token, token_type: token_type, expires_in: expiresIn, refresh_token: refresh_token, expires_at: expiresAt, region: region)
                    if let encodedToken = try? JSONEncoder().encode(token) {
                        KeychainWrapper.global.set(encodedToken, forKey: kTokenV3, withAccessibility: .afterFirstUnlock)
                    }
                }
                completion(token)
                return
            case .failure(let error):
                if error.statusCode == 400 {
                    if retries < 3 {
                        self.oauthCode(code, codeVerifier, region, retries: retries + 1, completion)
                        return
                    }
                    KeychainWrapper.global.removeObject(forKey: kTokenV3, withAccessibility: .afterFirstUnlock)
                } else if error.statusCode == 401 {
                    if retries < 3 {
                        self.oauthCode(code, codeVerifier, region, retries: retries + 1, completion)
                        return
                    }
                    KeychainWrapper.global.removeObject(forKey: kTokenV3, withAccessibility: .afterFirstUnlock)
                } else if error.statusCode == 848 {
                    // Mystical SSL error
                    if retries < 3 {
                        self.oauthCode(code, codeVerifier, region, retries: retries + 1, completion)
                        return
                    }
                } else {
                    // 19 - network connection was lost
                    // 23 - request timed out
                    if retries < 3 {
                        self.oauthCode(code, codeVerifier, region, retries: retries + 1, completion)
                        return
                    }
                    
                }
                completion(nil)
            }
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
        let verifier = "\(Date().toISO())\(Date().toISO())\(Date().toISO())".data(using: .utf8)!.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
            .prefix(43)
        return String(verifier)
    }

    var challenge: String {
        let data = Data(utf8)
        let hash = SHA256.hash(data: data)
        let base64 = Data(hash).base64EncodedString()
        let urlSafe = base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return urlSafe
    }
}
