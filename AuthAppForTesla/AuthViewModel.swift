//
//  AuthViewModel.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import Foundation
import Intents

@MainActor
class AuthViewModel: ObservableObject {
    @Published var tokenV3: Token?
    @Published var tokenV4: Token?
    
    init() {
        tokenV3 = AuthController.shared.v3Token
        tokenV4 = AuthController.shared.v4Token
    }
    
    public func refreshAll()
    {
        Task {
            tokenV3 = await AuthController.shared.acquireTokenV3Silent(forceRefresh: true)
            tokenV4 = await AuthController.shared.acquireTokenV4Silent(forceRefresh: true)
        }
    }

    public func logOut(environment: LoginEnvironment)
    {
        switch environment {
        case .owner:
            self.tokenV3 = nil
        case .fleet:
            self.tokenV4 = nil
        }
        AuthController.shared.logOut(environment: environment)
    }
    
    func setJwtToken(_ token: Token)
    {
        AuthController.shared.setJwtToken(token)
        self.tokenV3 = token
    }
    
    func acquireTokenSilentV3(forceRefresh: Bool = false) async -> Token? {
        let token = await AuthController.shared.acquireTokenV3Silent(forceRefresh: forceRefresh)
        tokenV3 = token
        return token
    }

    func acquireTokenSilentV4(forceRefresh: Bool = false) async -> Token? {
        let token = await AuthController.shared.acquireTokenV4Silent(forceRefresh: forceRefresh)
        tokenV4 = token
        return token
    }
}
