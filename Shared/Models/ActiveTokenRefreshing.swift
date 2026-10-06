//
//  ActiveTokenRefreshing.swift
//  AuthAppForTesla
//
//  What `AuthViewModel` needs to refresh and show the active tokens.
//  `AuthController` is the live one; tests inject a stub (#49).
//

import Foundation
import TeslaAuthKit

protocol ActiveTokenRefreshing: Sendable {
    /// Refreshes the active profile's token; offline and refused keep it.
    func refreshActive(environment: LoginEnvironment, forceRefresh: Bool) async -> TokenRefreshOutcome
    /// The active profile's stored token, without a refresh.
    func activeToken(environment: LoginEnvironment) async -> Token?
}

extension AuthController: ActiveTokenRefreshing {}
