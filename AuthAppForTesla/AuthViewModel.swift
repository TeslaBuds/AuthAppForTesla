//
//  AuthViewModel.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import Foundation
import Networking

class AuthViewModel: ObservableObject {
    @Published var tokenV3: Token?
    @Published var tokenV2: Token?
    
    init() {
        self.acquireTokenV3Silent { (token) in
            self.tokenV3 = token
        }
        self.acquireTokenSilent { (token) in
            self.tokenV2 = token
        }
    }
    
    
    private lazy var networkingAuth: Networking = {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.allowsCellularAccess = true
        return Networking(configuration: configuration)
    }()

    private lazy var networking: Networking = {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.allowsCellularAccess = true
        return Networking(baseURL: "https://owner-api.teslamotors.com", configuration: configuration)
    }()


    public func logOut()
    {
        self.tokenV2 = nil
        self.tokenV3 = nil
        KeychainWrapper.global.removeObject(forKey: kTokenV3, withAccessibility: .afterFirstUnlock)
        KeychainWrapper.global.removeObject(forKey: kTokenV2, withAccessibility: .afterFirstUnlock)
        KeychainWrapper.global.removeAllKeys()
    }
    
    func setJwtToken(_ token: Token)
    {
        if let encodedToken = try? JSONEncoder().encode(token) {
            logRequestEvent(message: "Setting V3 token from setJwtToken: \(encodedToken)")
            KeychainWrapper.global.set(encodedToken, forKey: kTokenV3, withAccessibility: .afterFirstUnlock)
            self.tokenV3 = token
        }
    }

    
    func getV2Token() -> Data? {
        if let tokenJson = KeychainWrapper.global.data(forKey: kTokenV2, withAccessibility: .afterFirstUnlock)
        {
            if (try? JSONDecoder().decode(Token.self, from: tokenJson)) != nil
            {
                return tokenJson
            }
        }
        return nil
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

    func acquireTokenV3Silent(_ completion: @escaping (Token?) -> ()) {
        var token: Token?
        if let tokenJson = getV3Token()
        { token = try? JSONDecoder().decode(Token.self, from: tokenJson) }
        
        if let token = token
        {
            if (token.expires_at ?? Date() <= Date().addingTimeInterval(60))
            {
                oauthRenew(token.refresh_token) { (refreshedToken) in
                    if let refreshedToken = refreshedToken, let encodedToken = try? JSONEncoder().encode(refreshedToken)
                    {
                        logRequestEvent(message: "Setting V3 token from acquireTokenV3Silent: \(encodedToken)")
                        KeychainWrapper.global.set(encodedToken, forKey: kTokenV3, withAccessibility: .afterFirstUnlock)
                        self.tokenV3 = refreshedToken
                    }
                    else
                    {
                        //self.logOut()
                        logRequestEvent(message: "Acquire v3 token silent error: Unable to refresh token")
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
        logRequestEvent(message: "Acquire v3 token silent error: Token not found")
//        self.logOut()
        completion(nil)
    }

    func getAuthRegion(completion: @escaping (_ result: String?) -> ()) {
        let url = URL(string: "https://auth-global.tesla.com/oauth2/v3/token")!
        let request = URLRequest(url: url)
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let response = response as? HTTPURLResponse {
                completion(response.url?.absoluteString)
            }
            else
            {
                completion(nil)
            }
        }
        task.resume()
    }

    fileprivate func oauthRenew(_ refreshToken: String, retries: Int = 0, _ completion: @escaping (Token?) -> ()) {
        getAuthRegion { (url) in
            guard let url = url else { completion(nil); return }
            
            self.networkingAuth.headerFields = ["User-Agent": "TeslaWatch"]
            self.networkingAuth.headerFields = ["X-Tesla-User-Agent": "TeslaWatch"]
            self.networkingAuth.post(url, parameterType: .formURLEncoded, parameters:
                [   "grant_type" : "refresh_token",
                    "scope" : "openid email offline_access",
                    "client_id" : "ownerapi",
                    "client_secret" : kTeslaSecret,
                    "refresh_token" : "\(refreshToken)"]
            ) { result in
                switch result {
                case .success(let result):
                    var token: Token? = nil
                    if let expiresIn = result.dictionaryBody["expires_in"] as? Int,
                    let access_token = result.dictionaryBody["access_token"] as? String,
                    let token_type = result.dictionaryBody["token_type"] as? String,
                    let refresh_token = result.dictionaryBody["refresh_token"] as? String
                    {
                        let expiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))

                        token = Token(access_token: access_token, token_type: token_type, expires_in: expiresIn, refresh_token: refresh_token, expires_at: expiresAt)
                        if let encodedToken = try? JSONEncoder().encode(token) {
                            logRequestEvent(message: "Setting V3 token from oauthRenew: \(encodedToken)")
                            KeychainWrapper.global.set(encodedToken, forKey: kTokenV3, withAccessibility: .afterFirstUnlock)
                            self.tokenV3 = token
                        }
                        if (refreshToken != refresh_token)
                        {
                            logRequestEvent(message: "Refresh token v3: Refresh token value updated during refresh")
                        }
                    }
                    logRequestEvent(message: "Refresh token v3 success: \(token == nil ? "Token received but was invalid" : "True")")
                    completion(token)
                    return
                case .failure(let error):
                    // print("Error refreshing token: \(error)")
                    if error.statusCode == 400
                    {
                        if retries < 3
                        {
                            logRequestEvent(message: "Refresh token v3 failure 400: retrying \(retries + 1)")
                            self.oauthRenew(refreshToken, retries: retries + 1, completion)
                            return
                        }
                        logRequestEvent(message: "Refresh token v3 failure 400: giving up")
                        logRequestEvent(message: "Refresh token v3 error 400, removing token")
                        logRequestEvent(message: "Removing V3 token from oauthRenew")
                        KeychainWrapper.global.removeObject(forKey: kTokenV3, withAccessibility: .afterFirstUnlock)
                        self.tokenV3 = nil
                        //KeychainWrapper.global.set("", forKey: kWatchToken, withAccessibility: .afterFirstUnlock)
                        //UserDefaults.standard.set(nil, forKey: kWatchToken)
                    }
                    else if error.statusCode == 401
                    {
                        if retries < 3
                        {
                            logRequestEvent(message: "Refresh token v3 failure 401: retrying \(retries + 1)")
                            self.oauthRenew(refreshToken, retries: retries + 1, completion)
                            return
                        }
                        logRequestEvent(message: "Refresh token v3 failure 401: giving up")
                        logRequestEvent(message: "Refresh token v3 error 401, removing token")
                        logRequestEvent(message: "Removing V3 token from oauthRenew")
                        KeychainWrapper.global.removeObject(forKey: kTokenV3, withAccessibility: .afterFirstUnlock)
                        self.tokenV3 = nil
                        //KeychainWrapper.global.set("", forKey: kWatchToken, withAccessibility: .afterFirstUnlock)
                        //UserDefaults.standard.set(nil, forKey: kWatchToken)
                    }
                    else if error.statusCode == 848
                    {
                        //Mystical SSL error
                        logRequestEvent(message: "Refresh token v3 failure: SSL 848")
                        if retries < 3
                        {
                            logRequestEvent(message: "Refresh token v3 failure: retrying \(retries + 1)")
                            self.oauthRenew(refreshToken, retries: retries + 1, completion)
                            return
                        }
                        logRequestEvent(message: "Refresh token v3 failure: giving up")
                    }
                    else
                    {
                        //19 - network connection was lost
                        //23 - request timed out

                        logRequestEvent(message: "Refresh token v3 error: \(error.headers["Www-Authenticate"] as? String ?? error.statusCode.description)")
                        if retries < 3
                        {
                            logRequestEvent(message: "Refresh token v3 failure \(error.statusCode.description): retrying \(retries + 1)")
                            self.oauthRenew(refreshToken, retries: retries + 1, completion)
                            return
                        }
                        logRequestEvent(message: "Refresh token v3 failure: giving up")
                        logRequestEvent(message: "Refresh token v3 failure: \(error.error.debugDescription)")
                        //set offline - not logged out
                        
                    }
                    completion(nil)
                }
            }
        }
    }

    fileprivate func refreshClassicTokenWithJWTToken(_ accessToken: String, retries: Int = 0, _ completion: @escaping (Token?) -> ()) {
        self.networking.headerFields = ["User-Agent": "TeslaWatch"]
        self.networking.headerFields = ["X-Tesla-User-Agent": "TeslaWatch"]
        self.networking.setAuthorizationHeader(token: accessToken)
        self.networking.post("/oauth/token", parameterType: .formURLEncoded, parameters:
            [   "grant_type" : "urn:ietf:params:oauth:grant-type:jwt-bearer",
                "client_id" : kTeslaClientID,
                "client_secret" : kTeslaSecret]
        ) { result in
            switch result {
            case .success(let result):
                let expiresIn = result.dictionaryBody["expires_in"] as! Int
                let expiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))
                var token = try? JSONDecoder().decode(Token.self, from: result.data)
                token?.expires_at = expiresAt
                if let encodedToken = try? JSONEncoder().encode(token) {
                    KeychainWrapper.global.set(encodedToken, forKey: kTokenV2, withAccessibility: .afterFirstUnlock)
                    self.tokenV2 = token
                }
                else
                {
                    logRequestEvent(message: "Unable to encode token! Data: \(String(decoding: result.data, as: UTF8.self))")
                }
                logRequestEvent(message: "Refresh token V4 success: \(token == nil ? "Token received but was invalid" : "True")")
                completion(token)
                return
            case .failure(let error):
                // print("Error refreshing token: \(error)")
                if error.statusCode == 400
                {
                    if retries < 3
                    {
                        logRequestEvent(message: "Refresh token v4 failure 400: retrying \(retries + 1)")
                        self.refreshClassicTokenWithJWTToken(accessToken, retries: retries + 1, completion)
                        return
                    }
                    logRequestEvent(message: "Refresh token v4 failure 400: giving up")
                    logRequestEvent(message: "Refresh token V4 error 400, removing token")
                    KeychainWrapper.global.removeObject(forKey: kTokenV2, withAccessibility: .afterFirstUnlock)
                    self.tokenV2 = nil
                    //KeychainWrapper.global.set("", forKey: kWatchToken, withAccessibility: .afterFirstUnlock)
                    //UserDefaults.standard.set(nil, forKey: kWatchToken)
                }
                else if error.statusCode == 401
                {
                    if retries < 3
                    {
                        logRequestEvent(message: "Refresh token v4 failure 401: retrying \(retries + 1)")
                        self.refreshClassicTokenWithJWTToken(accessToken, retries: retries + 1, completion)
                        return
                    }
                    logRequestEvent(message: "Refresh token v4 failure 401: giving up")
                    logRequestEvent(message: "Refresh token V4 error 401, removing token")
                    KeychainWrapper.global.removeObject(forKey: kTokenV2, withAccessibility: .afterFirstUnlock)
                    self.tokenV2 = nil
                    //KeychainWrapper.global.set("", forKey: kWatchToken, withAccessibility: .afterFirstUnlock)
                    //UserDefaults.standard.set(nil, forKey: kWatchToken)
                }
                else if error.statusCode == 848
                {
                    //Mystical SSL error
                    logRequestEvent(message: "Refresh token v4 failure: SSL 848")
                    if retries < 3
                    {
                        logRequestEvent(message: "Refresh token v4 failure: retrying \(retries + 1)")
                        self.refreshClassicTokenWithJWTToken(accessToken, retries: retries + 1, completion)
                        return
                    }
                    logRequestEvent(message: "Refresh token v4 failure: giving up")
                    
                }
                else
                {
                    //19 - network connection was lost
                    //23 - request timed out

                    logRequestEvent(message: "Refresh token V4 error: \(error.headers["Www-Authenticate"] as? String ?? error.statusCode.description)")
                    if retries < 3
                    {
                        logRequestEvent(message: "Refresh token v4 failure \(error.statusCode.description): retrying \(retries + 1)")
                        self.refreshClassicTokenWithJWTToken(accessToken, retries: retries + 1, completion)
                        return
                    }
                    logRequestEvent(message: "Refresh token v4 failure: giving up")
                    logRequestEvent(message: "Refresh token v4 failure: \(error.error.debugDescription)")
                }
                completion(nil)
            }
        }
    }

    func acquireTokenSilent(forceRefresh: Bool = false, _ completion: @escaping (Token?) -> ()) {
        var token: Token?
        if let tokenJson = KeychainWrapper.global.data(forKey: kTokenV2, withAccessibility: .afterFirstUnlock)
        {
            token = try? JSONDecoder().decode(Token.self, from: tokenJson)
        }
        
        if let token = token
        {
            //If token is v2 and is expired, get valid v3 (refresh if needed) then get new v2
            //If token is v2 and close to expiry or token is legacy v3 stored in wrong key and is close to expiry, we need to refresh
            if (forceRefresh || (!token.refresh_token.starts(with: "ey") && token.expires_at ?? Date() <= Date().addingTimeInterval(60*60*24*7)) || (token.refresh_token.starts(with: "ey") && token.expires_at ?? Date() <= Date().addingTimeInterval(60))) //Token expired - 7 days before expiry, refresh the token
            {
                //So to simplify - literally remove v2 token key, retry this method which will fall down to v3 and either work or fail
                logRequestEvent(message: "Removing expired v2 token")
                KeychainWrapper.global.removeObject(forKey: kTokenV2, withAccessibility: .afterFirstUnlock)
                self.tokenV2 = nil
                logRequestEvent(message: "V2 token expired, retrying v3")
                self.acquireTokenSilent(completion)
                return
            }
            //Return validated token
            //print(token)
            self.tokenV2 = token
            completion(token)
            return
        }
        else if let tokenv3 = getV3Token(), let _ = try? JSONDecoder().decode(Token.self, from: tokenv3)
        {
            acquireTokenV3Silent { (v3Token) in
                if let v3Token = v3Token
                {
                    self.refreshClassicTokenWithJWTToken(v3Token.access_token) { (refreshedToken) in
                        if let refreshedToken = refreshedToken, let _ = try? JSONEncoder().encode(refreshedToken)
                        {
                            //no-op
                        }
                        else
                        {
                            //self.logOut()
                            logRequestEvent(message: "Acquire token silent error: Unable to refresh token using refreshClassicTokenWithJWTToken")
                            self.tokenV2 = nil
                            completion(nil)
                            return
                        }
                        self.tokenV2 = refreshedToken
                        completion(refreshedToken)
                        return
                    }
                }
                else
                {
                    logRequestEvent(message: "Acquire token silent error: Unable to acquire v3 token")
                    self.tokenV2 = nil
                    completion(nil)
                    return
                }
            }
            //IMPORTANT!!! Need to return here, to not fall-through to below! Above method will ensure completion is eventually called!
            return
        }
        logRequestEvent(message: "Acquire token silent error: Token not found")
//        self.logOut()
        self.tokenV2 = nil
        completion(nil)
    }
}
