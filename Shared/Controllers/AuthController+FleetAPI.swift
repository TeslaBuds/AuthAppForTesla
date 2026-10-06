//
//  AuthViewModel.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import Foundation
import TeslaAuthKit

extension AuthController {
    public func storeFleetConnection(clientId: String, clientSecret: String, redirectUri: String) {
        // The sync-wipe guard (#44): never write synced items this device
        // could not read.
        for key in [kFleetClientID, kFleetClientSecret, kFleetRedirectUri] {
            if case .failed = KeychainWrapper.global.readResult(forKey: key, withAccessibility: .afterFirstUnlock) { return }
        }
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
    /// Returns the URL to present and the random `state` the redirect
    /// must carry back before its code is exchanged (#51).
    func buildOAuthURLV4(region: TokenRegion, fleetClientId: String, fleetRedirectUri: String) -> (url: URL, state: String)? {
        let authenticateUrl = getAuthByRegion(region: region)
        let state = PKCE.makeState()

        let authRequest = "\(authenticateUrl)/oauth2/v3/authorize?response_type=code&client_id=\(fleetClientId)&redirect_uri=\(fleetRedirectUri)&prompt=login&scope=openid%20vehicle_device_data%20vehicle_cmds%20vehicle_charging_cmds%20offline_access&state=\(state)"
        guard let url = URL(string: authRequest) else { return nil }
        return (url, state)
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
                        _ = try? await TokenProfileStore.shared.upsert(profile: profile, environment: .fleet, makeActive: true)
                    } else {
                        _ = try? await TokenProfileStore.shared.updateActiveToken(token, environment: .fleet)
                    }
                }
            }
            return token
        case .failure(let error):
            // A code is single-use; a failed sign-in never touches the
            // stored tokens (#49). Retry only a lost connection or 5xx.
            if Self.isRetryable(error), retries < 3 {
                return await oauthCodeV4(code, region, fleetClientId: fleetClientId, fleetSecret: fleetSecret, fleetRedirectUri: fleetRedirectUri, addAsNewProfile: addAsNewProfile, retries: retries + 1)
            }
            return nil
        }
    }

    /// Returns the V4 (Fleet API) token for a specific profile,
    /// refreshing if it's expired or about to expire. Does NOT change
    /// the active profile — used exclusively by the App Intent path
    /// when the user has explicitly chosen an account in their Shortcut.
    func acquireTokenV4Silent(profileId: UUID, forceRefresh: Bool = false) async -> Token? {
        await refreshService.refresh(environment: .fleet, profileId: profileId, forceRefresh: forceRefresh).freshToken
    }

    /// The active Fleet profile's token (see `v3Token`).
    var v4Token: Token? {
        get async { await activeToken(environment: .fleet) }
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

    /// The active Fleet token, refreshed when forced or due; nil when a
    /// needed refresh failed. Never deletes the profile (#50).
    func acquireTokenV4Silent(forceRefresh: Bool = false) async -> Token? {
        await refreshService.refresh(environment: .fleet, forceRefresh: forceRefresh).freshToken
    }
}
