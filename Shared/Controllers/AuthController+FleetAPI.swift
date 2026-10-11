//
//  AuthViewModel.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import Foundation
import TeslaAuthKit

extension AuthController {
    /// Stores the Fleet API client credentials in the synced keychain.
    /// Throws, writing nothing, when the synced items cannot be read on
    /// this device (the sync-wipe guard, #44), so no caller can report a
    /// save that did not happen (#54).
    func storeFleetConnection(_ credentials: FleetCredentials) throws(TokenStoreError) {
        try credentials.store(
            read: { KeychainWrapper.global.readResult(forKey: $0, withAccessibility: .afterFirstUnlock) },
            write: { KeychainWrapper.global.set($0, forKey: $1, withAccessibility: .afterFirstUnlock) }
        )
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
    ///
    /// Built from query items, like the Owners flow, so a redirect URI
    /// or client ID with reserved characters (`?`, `&`, `#`, spaces,
    /// non-ASCII) arrives at Tesla as one intact value (#53).
    func buildOAuthURLV4(region: TokenRegion, fleetClientId: String, fleetRedirectUri: String) -> (url: URL, state: String)? {
        let state = PKCE.makeState()
        guard let url = Self.fleetAuthorizeURL(
            authenticateUrl: getAuthByRegion(region: region),
            clientId: fleetClientId,
            redirectUri: fleetRedirectUri,
            state: state
        ) else { return nil }
        return (url, state)
    }

    /// The scopes a Fleet API sign-in asks for.
    static let fleetScope = "openid vehicle_device_data vehicle_cmds vehicle_charging_cmds offline_access"

    /// The Fleet API authorize URL, every value percent-encoded as one
    /// query item (#53).
    nonisolated static func fleetAuthorizeURL(authenticateUrl: String, clientId: String, redirectUri: String, state: String) -> URL? {
        guard var components = URLComponents(string: authenticateUrl) else { return nil }
        components.path = "/oauth2/v3/authorize"
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "prompt", value: "login"),
            URLQueryItem(name: "scope", value: fleetScope),
            URLQueryItem(name: "state", value: state)
        ]
        // `queryItems` leaves `+` alone, which a form-decoding server
        // reads as a space; encode it so a value round-trips exactly.
        components.percentEncodedQuery = components.percentEncodedQuery?.replacing("+", with: "%2B")
        return components.url
    }

    /// Exchanges an OAuth authorization code for a V4 (Fleet API) token.
    /// When `addAsNewProfile` is true, the resulting token is stored in a
    /// new profile instead of replacing the active profile's token.
    func exchangeCodeV4(_ code: String, region: TokenRegion, fleetClientId: String, fleetSecret: String, fleetRedirectUri: String, addAsNewProfile: Bool = false) async -> Token? {
        await oauthCodeV4(code, region, fleetClientId: fleetClientId, fleetSecret: fleetSecret, fleetRedirectUri: fleetRedirectUri, addAsNewProfile: addAsNewProfile)
    }

    fileprivate func oauthCodeV4(_ code: String, _ region: TokenRegion, fleetClientId: String, fleetSecret: String, fleetRedirectUri: String, addAsNewProfile: Bool = false) async -> Token? {
        let url = getAuthByRegion(region: region)
                
        let audience = "https://fleet-api.prd.\(String(code.prefix(2)).lowercased()).vn.cloud.tesla.\(region == .global ? "com" : "cn")"
        
        // Retry only a lost connection or a 5xx, with a short backoff (#60).
        let result = await CodeExchangeRetry.standard.run(isRetryable: Self.isRetryable) { _ in
            await NetworkController.shared.post("\(url)/oauth2/v3/token", parameters:
                                                            [   "grant_type": "authorization_code",
                                                                "client_id": fleetClientId,
                                                                "client_secret": fleetSecret,
                                                                "code": code,
                                                                "audience": audience,
                                                                "redirect_uri": fleetRedirectUri])
        }
        
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
                        let name = await store.suggestedName(for: .fleet)
                        let profile = TokenProfile(name: name, token: token)
                        _ = try? await store.upsert(profile: profile, environment: .fleet, makeActive: true)
                    } else {
                        _ = try? await store.updateActiveToken(token, environment: .fleet)
                    }
                }
            }
            if token != nil { await storeDidChange() }
            return token
        case .failure:
            // A code is single-use; a failed sign-in never touches the
            // stored tokens (#49).
            return nil
        }
    }

    /// Returns the V4 (Fleet API) token for a specific profile,
    /// refreshing if it's expired or about to expire. Does NOT change
    /// the active profile — used exclusively by the App Intent path
    /// when the user has explicitly chosen an account in their Shortcut.
    func acquireTokenV4Silent(profileId: UUID, forceRefresh: Bool = false) async -> Token? {
        await refresh(environment: .fleet, profileId: profileId, forceRefresh: forceRefresh).freshToken
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
        await refresh(environment: .fleet, profileId: nil, forceRefresh: forceRefresh).freshToken
    }
}
