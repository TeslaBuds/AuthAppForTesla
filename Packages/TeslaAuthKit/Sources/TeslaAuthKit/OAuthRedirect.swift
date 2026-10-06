//
//  OAuthRedirect.swift
//  TeslaAuthKit
//
//  Reads the authorization code from an OAuth redirect, but only after
//  the redirect's `state` matches the one this flow sent
//  (AuthAppForTesla#51). A mismatch means the redirect does not belong
//  to the sign-in the person started, so no code is ever exchanged.
//

import Foundation

public enum OAuthRedirectError: Error, Equatable {
    /// The redirect carried no `state`, or a different one.
    case stateMismatch
    /// The redirect carried an `error` parameter instead of a code.
    case authorizationError(String)
    /// The redirect carried no `code`.
    case missingCode
}

public enum OAuthRedirect {
    /// The authorization code in `url`, when its `state` equals `expectedState`.
    public static func authorizationCode(from url: URL, expectedState: String) -> Result<String, OAuthRedirectError> {
        let items = URLComponents(url: url, resolvingAgainstBaseURL: true)?.queryItems ?? []
        func value(_ name: String) -> String? { items.first(where: { $0.name == name })?.value }

        guard !expectedState.isEmpty, let state = value("state"), constantTimeEquals(state, expectedState) else {
            return .failure(.stateMismatch)
        }
        if let error = value("error") {
            return .failure(.authorizationError(value("error_description") ?? error))
        }
        guard let code = value("code"), !code.isEmpty else {
            return .failure(.missingCode)
        }
        return .success(code)
    }

    /// Compares without returning early on the first differing byte.
    static func constantTimeEquals(_ lhs: String, _ rhs: String) -> Bool {
        let a = Array(lhs.utf8), b = Array(rhs.utf8)
        guard a.count == b.count else { return false }
        var difference: UInt8 = 0
        for index in a.indices { difference |= a[index] ^ b[index] }
        return difference == 0
    }
}
