//
//  AuthViewModel.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import Foundation
import UIKit

extension AuthController {
    func randomANSICharacter() -> Character {
        // ANSI characters range from 32 to 126 in the ASCII table
        let asciiCode = Int.random(in: 97...122)
        return Character(UnicodeScalar(asciiCode)!)
    }
    
    func createStateString(length: Int) -> String {
        let statePrefix = "$STATE"
        var randomString = statePrefix
        for _ in 0..<(length - statePrefix.count) {
            randomString.append(randomANSICharacter())
        }
        return randomString
    }

    public func storeFleetConnection(clientId: String, clientSecret: String, redirectUri: String) {
        KeychainWrapper.global.set(clientId, forKey: kFleetClientID, withAccessibility: .afterFirstUnlock)
        KeychainWrapper.global.set(clientSecret, forKey: kFleetClientSecret, withAccessibility: .afterFirstUnlock)
        KeychainWrapper.global.set(redirectUri, forKey: kFleetRedirectUri, withAccessibility: .afterFirstUnlock)
    }

    var fleetClientId: String {
        return KeychainWrapper.global.string(forKey: kFleetClientID) ?? ""
    }

    var fleetClientSecret: String {
        return KeychainWrapper.global.string(forKey: kFleetClientSecret) ?? ""
    }

    var fleetRedirectUri: String {
        return KeychainWrapper.global.string(forKey: kFleetRedirectUri) ?? ""
    }

#if OAUTHAVAILABLE
    public func authenticateWebV4(region: TokenRegion, fleetClientId: String, fleetSecret: String, fleetRedirectUri: String, completion: @escaping (Result<Token, Error>) -> Void) -> AuthWebViewController? {
        let authenticateUrl = getAuthByRegion(region: region)
        
        let stateString = createStateString(length: 40)
        
        let authRequest = "\(authenticateUrl)/oauth2/v3/authorize?response_type=code&client_id=\(fleetClientId)&redirect_uri=\(fleetRedirectUri)&prompt=login&scope=openid%20vehicle_device_data%20vehicle_cmds%20vehicle_charging_cmds%20offline_access&state=\(stateString)"
        let authRequestUrl = URL(string: authRequest)!
        
        let teslaWebLoginViewController = AuthWebViewController(url: authRequestUrl, redirectUrl: fleetRedirectUri)
        
        teslaWebLoginViewController.result = { result in
            switch result {
            case let .success(url):
                let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
                if let queryItems = urlComponents?.queryItems {
                    for queryItem in queryItems {
                        if queryItem.name == "code", let code = queryItem.value {
                            Task {
                                let token = await self.oauthCodeV4(code, region, fleetClientId: fleetClientId, fleetSecret: fleetSecret, fleetRedirectUri: fleetRedirectUri)
                                if let token = token {
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
    
#endif
    
    fileprivate func oauthCodeV4(_ code: String, _ region: TokenRegion, fleetClientId: String, fleetSecret: String, fleetRedirectUri: String, retries: Int = 0) async -> Token? {
        let url = getAuthByRegion(region: region)
                
        let audience = "https://fleet-api.prd.\(String(code.prefix(2)).lowercased()).vn.cloud.tesla.\(region == .global ? "com" : "cn")"
        
        let result = await NetworkController.shared.post("\(url)/oauth2/v3/token", parameters:
                                                            [   "grant_type": "authorization_code",
                                                                "client_id": fleetClientId,
                                                                "client_secret": fleetSecret,
                                                                "code": code,
                                                                "audience": audience,
                                                                "redirect_uri": fleetRedirectUri])
        
        switch result {
        case .success(let result):
            //                print(String(decoding: result.data, as: UTF8.self))
            var token: Token?
            if let expiresIn = result.dictionaryBody["expires_in"] as? Int,
               let access_token = result.dictionaryBody["access_token"] as? String,
               let token_type = result.dictionaryBody["token_type"] as? String,
               let refresh_token = result.dictionaryBody["refresh_token"] as? String {
                let expiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))
                
                token = Token(access_token: access_token, token_type: token_type, expires_in: expiresIn, refresh_token: refresh_token, expires_at: expiresAt, region: region)
                if let encodedToken = try? JSONEncoder().encode(token) {
                    KeychainWrapper.global.set(encodedToken, forKey: kTokenV4, withAccessibility: .afterFirstUnlock)
                }
            }
            return token
        case .failure(let error):
            if error.statusCode == 400 {
                if retries < 3 {
                    return await oauthCodeV4(code, region, fleetClientId: fleetClientId, fleetSecret: fleetSecret, fleetRedirectUri: fleetRedirectUri, retries: retries + 1)
                }
                KeychainWrapper.global.removeObject(forKey: kTokenV4, withAccessibility: .afterFirstUnlock)
            } else if error.statusCode == 401 {
                if retries < 3 {
                    return await oauthCodeV4(code, region, fleetClientId: fleetClientId, fleetSecret: fleetSecret, fleetRedirectUri: fleetRedirectUri, retries: retries + 1)
                }
                KeychainWrapper.global.removeObject(forKey: kTokenV4, withAccessibility: .afterFirstUnlock)
            } else if error.statusCode == 848 {
                // Mystical SSL error
                if retries < 3 {
                    return await oauthCodeV4(code, region, fleetClientId: fleetClientId, fleetSecret: fleetSecret, fleetRedirectUri: fleetRedirectUri, retries: retries + 1)
                }
            } else {
                // 19 - network connection was lost
                // 23 - request timed out
                
                if retries < 3 {
                    return await oauthCodeV4(code, region, fleetClientId: fleetClientId, fleetSecret: fleetSecret, fleetRedirectUri: fleetRedirectUri, retries: retries + 1)
                }
            }
            return nil
        }
    }
    
    fileprivate func oauthRenewV4(_ refreshToken: String, _ region: TokenRegion, fleetClientId: String, retries: Int = 0) async -> Token? {
        let url = getAuthByRegion(region: region)
        
        let result = await NetworkController.shared.post("\(url)/oauth2/v3/token", parameters:
                                                    [   "grant_type": "refresh_token",
                                                        "client_id": fleetClientId,
                                                        "refresh_token": "\(refreshToken)"])
        switch result {
        case .success(let result):
            if let error = result.dictionaryBody["error"] as? String, error.count > 0 {
                if error == "login_required" {
                    self.logOut(environment: .fleet)
                    return nil
                }
            }
            
            var token: Token?
            if let expiresIn = result.dictionaryBody["expires_in"] as? Int,
               let access_token = result.dictionaryBody["access_token"] as? String,
               let token_type = result.dictionaryBody["token_type"] as? String,
               let refresh_token = result.dictionaryBody["refresh_token"] as? String {
                let expiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))
                
                token = Token(access_token: access_token, token_type: token_type, expires_in: expiresIn, refresh_token: refresh_token, expires_at: expiresAt, region: region)
                if let encodedToken = try? JSONEncoder().encode(token) {
                    KeychainWrapper.global.set(encodedToken, forKey: kTokenV4, withAccessibility: .afterFirstUnlock)
                }
            }
            return token
        case .failure(let error):
            if error.statusCode == 400 {
                if retries < 3 {
                    return await oauthRenewV4(refreshToken, region, fleetClientId: fleetClientId, retries: retries + 1)
                }
                KeychainWrapper.global.removeObject(forKey: kTokenV4, withAccessibility: .afterFirstUnlock)
            } else if error.statusCode == 401 {
                if retries < 3 {
                    return await oauthRenewV4(refreshToken, region, fleetClientId: fleetClientId, retries: retries + 1)
                }
                KeychainWrapper.global.removeObject(forKey: kTokenV4, withAccessibility: .afterFirstUnlock)
            } else if error.statusCode == 848 {
                // Mystical SSL error
                if retries < 3 {
                    return await oauthRenewV4(refreshToken, region, fleetClientId: fleetClientId, retries: retries + 1)
                }
            } else {
                // 19 - network connection was lost
                // 23 - request timed out
                if retries < 3 {
                    return await oauthRenewV4(refreshToken, region, fleetClientId: fleetClientId, retries: retries + 1)
                }
            }
            return nil
        }
    }

    var v4Token: Token? {
        var token: Token?
        if let tokenJson = getV4Token() { token = try? JSONDecoder().decode(Token.self, from: tokenJson) }
        
        return token
    }

    func getV4Token() -> Data? {
        if let tokenJson = KeychainWrapper.global.data(forKey: kTokenV4, withAccessibility: .afterFirstUnlock)
        {
            if (try? JSONDecoder().decode(Token.self, from: tokenJson)) != nil
            {
                return tokenJson
            }
        }
        return nil
    }

    func acquireTokenV4Silent(forceRefresh: Bool = false) async -> Token? {
        if let token = v4Token {
            if (forceRefresh || token.expires_at ?? Date() <= Date().addingTimeInterval(60)) {
                
                let refreshedToken = await oauthRenewV4(token.refresh_token, token.region ?? .global, fleetClientId: fleetClientId)
                if let refreshedToken, let encodedToken = try? JSONEncoder().encode(refreshedToken) {
                    KeychainWrapper.global.set(encodedToken, forKey: kTokenV4, withAccessibility: .afterFirstUnlock)
                } else {
                    return nil
                }
                return refreshedToken
            }
            return token
        }
        return nil
    }
}
