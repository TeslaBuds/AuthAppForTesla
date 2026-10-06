//
//  TokenEndpointResponse.swift
//  TeslaAuthKit
//
//  What Tesla's token endpoint said to a refresh, sorted into the three
//  cases the app must treat differently (AuthAppForTesla#48–#50):
//
//  - a new token;
//  - the refresh token itself was refused (sign-in needed, but the
//    stored account is kept);
//  - Tesla could not be reached or failed, which says nothing about the
//    token (offline: keep showing the stored token, retry later).
//

import Foundation

public enum TokenEndpointResponse {
    case token(Token)
    /// Tesla refused the refresh token. The reason is its `error_description`.
    case rejected(reason: String)
    /// No answer, or one that says nothing about the token.
    case unavailable(reason: String)

    /// OAuth `error` codes that mean the refresh token itself is dead.
    static let rejectionCodes: Set<String> = [
        "login_required", "invalid_grant", "invalid_token", "unauthorized_client", "invalid_client",
    ]

    /// Classifies one token-endpoint exchange.
    ///
    /// - Parameters:
    ///   - statusCode: the HTTP status, or nil when no response arrived.
    ///   - body: the response body.
    ///   - transportError: the URL loading error, when the request failed.
    ///   - region: stamped on the new token.
    public static func classify(
        statusCode: Int?,
        body: Data,
        transportError: Error?,
        region: TokenRegion,
        now: Date = .now
    ) -> TokenEndpointResponse {
        if let transportError {
            return .unavailable(reason: transportError.localizedDescription)
        }
        guard let statusCode else {
            return .unavailable(reason: "Tesla did not answer.")
        }
        let dictionary = (try? JSONSerialization.jsonObject(with: body)) as? [String: Any] ?? [:]
        let error = (dictionary["error"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        let description = (dictionary["error_description"] as? String).flatMap { $0.isEmpty ? nil : $0 }

        switch statusCode {
        case 200..<300:
            if let error {
                let reason = description ?? error
                return rejectionCodes.contains(error) ? .rejected(reason: reason) : .unavailable(reason: reason)
            }
            guard let expiresIn = dictionary["expires_in"] as? Int,
                  let accessToken = dictionary["access_token"] as? String,
                  let tokenType = dictionary["token_type"] as? String,
                  let refreshToken = dictionary["refresh_token"] as? String else {
                return .unavailable(reason: "Tesla returned an unexpected response.")
            }
            return .token(Token(
                access_token: accessToken,
                token_type: tokenType,
                expires_in: expiresIn,
                refresh_token: refreshToken,
                expires_at: now.addingTimeInterval(TimeInterval(expiresIn)),
                region: region
            ))
        case 400, 401, 403:
            return .rejected(reason: description ?? error ?? "Tesla answered HTTP \(statusCode).")
        default:
            return .unavailable(reason: description ?? "Tesla answered HTTP \(statusCode).")
        }
    }
}
