//
//  AuthViewModel.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import Foundation
import Intents

class AuthViewModel: ObservableObject {
    @Published var tokenV3: Token?
    @Published var tokenV4: Token?
    @Published var externalTokenRequest: ExternalTokenRequest?
    
    init() {
        AuthController.shared().acquireTokenV3Silent { (token) in
            self.tokenV3 = token
        }
        AuthController.shared().acquireTokenV4Silent { (token) in
            self.tokenV4 = token
        }
    }
    
    public func refreshAll()
    {
        AuthController.shared().acquireTokenV3Silent(forceRefresh: true) { (token) in
            DispatchQueue.main.async {
                self.tokenV3 = token
            }
        }
        AuthController.shared().acquireTokenV4Silent(forceRefresh: true) { (token) in
            DispatchQueue.main.async {
                self.tokenV4 = token
            }
        }
    }

    public func logOut()
    {
        self.tokenV3 = nil
        self.tokenV4 = nil
        AuthController.shared().logOut()
    }
    
    func setJwtToken(_ token: Token)
    {
        AuthController.shared().setJwtToken(token)
        self.tokenV3 = token
    }
    
    func acquireTokenSilent(forceRefresh: Bool = false, _ completion: @escaping (Token?) -> ()) {
        AuthController.shared().acquireTokenV3Silent(forceRefresh: forceRefresh) { token in
            DispatchQueue.main.async {
                self.tokenV3 = token
            }
            completion(token)
        }
    }

    func donateRefreshTokenInteraction() {
        let intent = GetRefreshTokenIntent()
        
        intent.suggestedInvocationPhrase = "Get refresh token"
        
        let interaction = INInteraction(intent: intent, response: nil)
        
        interaction.donate { (error) in
            if error != nil {
                if let error = error as NSError? {
                    print("Interaction donation failed: \(error.description)")
                } else {
                    print("Successfully donated interaction")
                }
            }
        }
    }

    func donateAccessTokenInteraction() {
        let intent = GetAccessTokenIntent()
        
        intent.suggestedInvocationPhrase = "Get access token"
        
        let interaction = INInteraction(intent: intent, response: nil)
        
        interaction.donate { (error) in
            if error != nil {
                if let error = error as NSError? {
                    print("Interaction donation failed: \(error.description)")
                } else {
                    print("Successfully donated interaction")
                }
            }
        }
    }
}
