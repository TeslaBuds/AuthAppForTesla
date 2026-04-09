//
//  AuthViewModel.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import Foundation

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
        KeychainWrapper.global.string(forKey: kFleetClientID) ?? ""
    }

    var fleetClientSecret: String {
        KeychainWrapper.global.string(forKey: kFleetClientSecret) ?? ""
    }

    var fleetRedirectUri: String {
        KeychainWrapper.global.string(forKey: kFleetRedirectUri) ?? ""
    }

    /// Builds the OAuth authorization URL for V4 (Fleet API) login.
    /// Returns the URL needed to present to the user.
    func buildOAuthURLV4(region: TokenRegion, fleetClientId: String, fleetRedirectUri: String) -> URL? {
        let authenticateUrl = getAuthByRegion(region: region)
        let stateString = createStateString(length: 40)

        let authRequest = "\(authenticateUrl)/oauth2/v3/authorize?response_type=code&client_id=\(fleetClientId)&redirect_uri=\(fleetRedirectUri)&prompt=login&scope=openid%20vehicle_device_data%20vehicle_cmds%20vehicle_charging_cmds%20offline_access&state=\(stateString)"
        return URL(string: authRequest)
    }

    /// Exchanges an OAuth authorization code for a V4 (Fleet API) token.
    /// When `addAsNewProfile` is true, the resulting token is stored in a
    /// new profile instead of replacing the active profile's token.
    func exchangeCodeV4(_ code: String, region: TokenRegion, fleetClientId: String, fleetSecret: String, fleetRedirectUri: String, addAsNewProfile: Bool = false) async -> Token? {
        await oauthCodeV4(code, region, fleetClientId: fleetClientId, fleetSecret: fleetSecret, fleetRedirectUri: fleetRedirectUri, addAsNewProfile: addAsNewProfile)
    }

    fileprivate func oauthCodeV4(_ code: String, _ region: TokenRegion, fleetClientId: String, fleetSecret: String, fleetRedirectUri: String, addAsNewProfile: Bool = false, retries: Int = 0) async -> Token? {
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
                if let token {
                    if addAsNewProfile {
                        let name = await TokenProfileStore.shared.suggestedName(for: .fleet)
                        let profile = TokenProfile(name: name, token: token)
                        await TokenProfileStore.shared.upsert(profile: profile, environment: .fleet, makeActive: true)
                    } else {
                        await TokenProfileStore.shared.updateActiveToken(token, environment: .fleet)
                    }
                }
            }
            return token
        case .failure(let error):
            if error.statusCode == 400 {
                if retries < 3 {
                    return await oauthCodeV4(code, region, fleetClientId: fleetClientId, fleetSecret: fleetSecret, fleetRedirectUri: fleetRedirectUri, addAsNewProfile: addAsNewProfile, retries: retries + 1)
                }
                KeychainWrapper.global.removeObject(forKey: kTokenV4, withAccessibility: .afterFirstUnlock)
            } else if error.statusCode == 401 {
                if retries < 3 {
                    return await oauthCodeV4(code, region, fleetClientId: fleetClientId, fleetSecret: fleetSecret, fleetRedirectUri: fleetRedirectUri, addAsNewProfile: addAsNewProfile, retries: retries + 1)
                }
                KeychainWrapper.global.removeObject(forKey: kTokenV4, withAccessibility: .afterFirstUnlock)
            } else if error.statusCode == 848 {
                // Mystical SSL error
                if retries < 3 {
                    return await oauthCodeV4(code, region, fleetClientId: fleetClientId, fleetSecret: fleetSecret, fleetRedirectUri: fleetRedirectUri, addAsNewProfile: addAsNewProfile, retries: retries + 1)
                }
            } else {
                // 19 - network connection was lost
                // 23 - request timed out

                if retries < 3 {
                    return await oauthCodeV4(code, region, fleetClientId: fleetClientId, fleetSecret: fleetSecret, fleetRedirectUri: fleetRedirectUri, addAsNewProfile: addAsNewProfile, retries: retries + 1)
                }
            }
            return nil
        }
    }
    
    /// Refreshes a V4 (Fleet API) refresh token. When `targetProfileId`
    /// is provided, the refreshed token is written back to that profile
    /// in the store rather than the currently active one. App Intents
    /// that operate on a non-active profile use this so they don't
    /// accidentally promote the chosen profile to active.
    func oauthRenewV4(_ refreshToken: String, _ region: TokenRegion, fleetClientId: String, targetProfileId: UUID? = nil, retries: Int = 0) async -> Token? {
        let url = getAuthByRegion(region: region)

        let result = await NetworkController.shared.post("\(url)/oauth2/v3/token", parameters:
                                                    [   "grant_type": "refresh_token",
                                                        "client_id": fleetClientId,
                                                        "refresh_token": "\(refreshToken)"])
        switch result {
        case .success(let result):
            if let error = result.dictionaryBody["error"] as? String, error.count > 0 {
                if error == "login_required" {
                    await self.logOut(environment: .fleet)
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
                if let token {
                    if let targetProfileId {
                        await TokenProfileStore.shared.updateProfileToken(id: targetProfileId, token: token, environment: .fleet)
                    } else {
                        await TokenProfileStore.shared.updateActiveToken(token, environment: .fleet)
                    }
                }
            }
            return token
        case .failure(let error):
            if error.statusCode == 400 {
                if retries < 3 {
                    return await oauthRenewV4(refreshToken, region, fleetClientId: fleetClientId, targetProfileId: targetProfileId, retries: retries + 1)
                }
                KeychainWrapper.global.removeObject(forKey: kTokenV4, withAccessibility: .afterFirstUnlock)
            } else if error.statusCode == 401 {
                if retries < 3 {
                    return await oauthRenewV4(refreshToken, region, fleetClientId: fleetClientId, targetProfileId: targetProfileId, retries: retries + 1)
                }
                KeychainWrapper.global.removeObject(forKey: kTokenV4, withAccessibility: .afterFirstUnlock)
            } else if error.statusCode == 848 {
                // Mystical SSL error
                if retries < 3 {
                    return await oauthRenewV4(refreshToken, region, fleetClientId: fleetClientId, targetProfileId: targetProfileId, retries: retries + 1)
                }
            } else {
                // 19 - network connection was lost
                // 23 - request timed out
                if retries < 3 {
                    return await oauthRenewV4(refreshToken, region, fleetClientId: fleetClientId, targetProfileId: targetProfileId, retries: retries + 1)
                }
            }
            return nil
        }
    }

    /// Returns the V4 (Fleet API) token for a specific profile,
    /// refreshing if it's expired or about to expire. Does NOT change
    /// the active profile — used exclusively by the App Intent path
    /// when the user has explicitly chosen an account in their Shortcut.
    func acquireTokenV4Silent(profileId: UUID, forceRefresh: Bool = false) async -> Token? {
        let collection = await TokenProfileStore.shared.load(environment: .fleet)
        guard let profile = collection.profiles.first(where: { $0.id == profileId }) else {
            return nil
        }
        let token = profile.token
        if forceRefresh || (token.expires_at ?? Date()) <= Date().addingTimeInterval(60) {
            return await oauthRenewV4(token.refresh_token, token.region ?? .global, fleetClientId: fleetClientId, targetProfileId: profileId)
        }
        return token
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
                if let refreshedToken {
                    await TokenProfileStore.shared.updateActiveToken(refreshedToken, environment: .fleet)
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
