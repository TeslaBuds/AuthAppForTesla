//
//  AuthViewModel.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import Foundation

class AuthController {
    private static var sharedAuthController: AuthController = {
        let authController = AuthController()
        return authController
    }()
    
    class func shared() -> AuthController {
        return sharedAuthController
    }

    public func logOut()
    {
        KeychainWrapper.global.removeObject(forKey: kTokenV3, withAccessibility: .afterFirstUnlock)
        KeychainWrapper.global.removeObject(forKey: kTokenV2, withAccessibility: .afterFirstUnlock)
        KeychainWrapper.global.removeAllKeys()
    }
    
    func setJwtToken(_ token: Token)
    {
        if let encodedToken = try? JSONEncoder().encode(token) {
            logRequestEvent(message: "Setting V3 token from setJwtToken: \(encodedToken)")
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
                        logRequestEvent(message: "Setting V3 token from acquireTokenV3Silent: \(encodedToken)")
                        KeychainWrapper.global.set(encodedToken, forKey: kTokenV3, withAccessibility: .afterFirstUnlock)
//                        self.tokenV3 = refreshedToken
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

    func getAuthRegion(region: TokenRegion, completion: @escaping (_ result: String?) -> ()) {
        switch region {
        case .global:
            completion("https://auth.tesla.com/oauth2/v3/token")
            return
        case.china:
            completion("https://auth.tesla.cn/oauth2/v3/token")
            return
        }
    }

    fileprivate func oauthRenew(_ refreshToken: String, _ region: TokenRegion, retries: Int = 0, _ completion: @escaping (Token?) -> ()) {
        getAuthRegion(region: region) { (url) in
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

                        token = Token(access_token: access_token, token_type: token_type, expires_in: expiresIn, refresh_token: refresh_token, expires_at: expiresAt, region: region)
                        if let encodedToken = try? JSONEncoder().encode(token) {
                            logRequestEvent(message: "Setting V3 token from oauthRenew: \(encodedToken)")
                            KeychainWrapper.global.set(encodedToken, forKey: kTokenV3, withAccessibility: .afterFirstUnlock)
//                            self.tokenV3 = token
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
                    if let stringData = String(data: error.data, encoding: .utf8) {
                        logRequestEvent(message: "Error response body: \(stringData)")
                    }

                    if error.statusCode == 400
                    {
                        if retries < 3
                        {
                            logRequestEvent(message: "Refresh token v3 failure 400: retrying \(retries + 1)")
                            self.oauthRenew(refreshToken, region, retries: retries + 1, completion)
                            return
                        }
                        logRequestEvent(message: "Refresh token v3 failure 400: giving up")
                        logRequestEvent(message: "Refresh token v3 error 400, removing token")
                        logRequestEvent(message: "Removing V3 token from oauthRenew")
                        KeychainWrapper.global.removeObject(forKey: kTokenV3, withAccessibility: .afterFirstUnlock)
                    }
                    else if error.statusCode == 401
                    {
                        if retries < 3
                        {
                            logRequestEvent(message: "Refresh token v3 failure 401: retrying \(retries + 1)")
                            self.oauthRenew(refreshToken, region, retries: retries + 1, completion)
                            return
                        }
                        logRequestEvent(message: "Refresh token v3 failure 401: giving up")
                        logRequestEvent(message: "Refresh token v3 error 401, removing token")
                        logRequestEvent(message: "Removing V3 token from oauthRenew")
                        KeychainWrapper.global.removeObject(forKey: kTokenV3, withAccessibility: .afterFirstUnlock)
                    }
                    else if error.statusCode == 848
                    {
                        //Mystical SSL error
                        logRequestEvent(message: "Refresh token v3 failure: SSL 848")
                        if retries < 3
                        {
                            logRequestEvent(message: "Refresh token v3 failure: retrying \(retries + 1)")
                            self.oauthRenew(refreshToken, region, retries: retries + 1, completion)
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
                            self.oauthRenew(refreshToken, region, retries: retries + 1, completion)
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
}
