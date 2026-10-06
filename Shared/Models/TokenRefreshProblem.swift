//
//  TokenRefreshProblem.swift
//  AuthAppForTesla
//
//  Why the last refresh of an API's active token did not succeed. Both
//  cases keep the stored token on screen (#49, #50); they only differ
//  in what the person can do about it.
//

import Foundation
import TeslaAuthKit

struct TokenRefreshProblem: Equatable {
    enum Kind: Equatable {
        /// Tesla could not be reached. Retrying later is enough.
        case offline
        /// Tesla refused the refresh token. Signing in again replaces it.
        case needsSignIn
    }

    let kind: Kind
    /// Tesla's description, or the connection error.
    let reason: String
    /// The refresh token this is about. A different (newer) token means
    /// the problem no longer applies.
    let refreshToken: String

    init?(_ outcome: TokenRefreshOutcome) {
        switch outcome {
        case .offline(let token, let reason):
            self.init(kind: .offline, reason: reason, refreshToken: token.refresh_token)
        case .needsSignIn(let token, let reason):
            self.init(kind: .needsSignIn, reason: reason, refreshToken: token.refresh_token)
        case .noToken, .current, .refreshed:
            return nil
        }
    }

    init(kind: Kind, reason: String, refreshToken: String) {
        self.kind = kind
        self.reason = reason
        self.refreshToken = refreshToken
    }

    /// What the Home header and the menu bar say.
    var message: String {
        switch kind {
        case .offline:
            String(localized: "Couldn't reach Tesla, so this token wasn't refreshed. Your saved token is unchanged.")
        case .needsSignIn:
            String(localized: "Tesla no longer accepts this refresh token. Sign in again to replace it — the account stays until you do.")
        }
    }
}
