//
//  AuthViewModel.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import Foundation

/// Shared observable model that holds the current authentication state
/// for both Owners API (v3) and Fleet API (v4) tokens.
@MainActor
@Observable
class AuthViewModel {
    var tokenV3: Token?
    var tokenV4: Token?

    init() {
        // Tokens are loaded asynchronously after init via loadTokens()
    }

    /// Loads the initial token state from the AuthController actor.
    func loadTokens() async {
        tokenV3 = await AuthController.shared.v3Token
        tokenV4 = await AuthController.shared.v4Token
    }

    func refreshAll() {
        Task {
            tokenV3 = await AuthController.shared.acquireTokenV3Silent(forceRefresh: true)
            tokenV4 = await AuthController.shared.acquireTokenV4Silent(forceRefresh: true)
        }
    }

    func logOut(environment: LoginEnvironment) {
        switch environment {
        case .owner:
            tokenV3 = nil
        case .fleet:
            tokenV4 = nil
        }
        Task {
            await AuthController.shared.logOut(environment: environment)
        }
    }

    func setJwtToken(_ token: Token) {
        Task {
            await AuthController.shared.setJwtToken(token)
        }
        tokenV3 = token
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
