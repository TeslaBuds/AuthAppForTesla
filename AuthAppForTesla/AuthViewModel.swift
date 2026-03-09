//
//  AuthViewModel.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import Foundation
import WidgetKit

/// Shared observable model that holds the current authentication state
/// for both Owners API (v3) and Fleet API (v4) tokens.
@MainActor
@Observable
class AuthViewModel {
    var tokenV3: Token? {
        didSet { persistTokenSummary() }
    }

    var tokenV4: Token? {
        didSet { persistTokenSummary() }
    }

    /// The currently visible toast notification, if any.
    var toast: Toast?

    init() {
        // Tokens are loaded asynchronously after init via loadTokens()
    }

    /// Presents a toast message.
    func showToast(_ toast: Toast) {
        self.toast = toast
    }

    /// Loads the initial token state from the AuthController actor.
    func loadTokens() async {
        tokenV3 = await AuthController.shared.v3Token
        tokenV4 = await AuthController.shared.v4Token
    }

    func refreshAll() {
        Task {
            let v3 = await AuthController.shared.acquireTokenV3Silent(forceRefresh: true)
            let v4 = await AuthController.shared.acquireTokenV4Silent(forceRefresh: true)
            tokenV3 = v3
            tokenV4 = v4
            if v3 == nil && v4 == nil {
                showToast(.error("Could not refresh tokens. Please sign in again."))
            } else {
                showToast(.success("Tokens refreshed successfully."))
            }
        }
    }

    /// Writes a lightweight token summary to the shared App Group UserDefaults
    /// so the WidgetKit extension can read expiry dates without keychain access.
    private func persistTokenSummary() {
        let defaults = UserDefaults(suiteName: "group.global")
        defaults?.set(tokenV3?.expires_at, forKey: "widget.tokenV3.expiresAt")
        defaults?.set(tokenV4?.expires_at, forKey: "widget.tokenV4.expiresAt")
        defaults?.set(tokenV3 != nil, forKey: "widget.tokenV3.hasToken")
        defaults?.set(tokenV4 != nil, forKey: "widget.tokenV4.hasToken")
        WidgetCenter.shared.reloadAllTimelines()
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
