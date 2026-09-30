//
//  TokenExpirationIntent.swift
//  AuthAppForTesla
//
//  Shared behaviour of the two "Get … Token Expiration" intents (#2):
//  look up a stored token's expiry without refreshing it, so a Shortcut
//  can branch on it and only open the app when a refresh is needed.
//

import Foundation
import AppIntents

enum TokenExpirationIntent {
    /// Reports when the stored access token for `environment` expires.
    /// Read-only: no refresh, no keychain writes.
    static func expiration(
        environment: LoginEnvironment,
        accountId: String?
    ) throws -> (date: Date, dialog: IntentDialog) {
        let collection = StoredTokenReader.profiles(for: environment)
        // A picked account that no longer parses or exists reports "no
        // token" rather than quietly falling back to the active account.
        let pickedId: UUID?
        if let accountId {
            guard let id = UUID(uuidString: accountId) else { throw TokenExpirationError.noToken(environment) }
            pickedId = id
        } else {
            pickedId = nil
        }
        guard let profile = StoredTokenReader.profile(in: collection, id: pickedId) else {
            throw TokenExpirationError.noToken(environment)
        }
        guard let date = StoredTokenReader.expirationDate(of: profile.token) else {
            throw TokenExpirationError.unknownExpiry(environment)
        }
        let when = date.formatted(date: .abbreviated, time: .shortened)
        let dialog: IntentDialog = date > .now
            ? "The access token expires \(when)."
            : "The access token expired \(when). Open Auth for Tesla to refresh it."
        return (date, dialog)
    }
}

enum TokenExpirationError: Error, CustomLocalizedStringResourceConvertible {
    case noToken(LoginEnvironment)
    case unknownExpiry(LoginEnvironment)

    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noToken(.owner):
            "There is no stored Owners API token. Open Auth for Tesla to sign in."
        case .noToken(.fleet):
            "There is no stored Fleet API token. Open Auth for Tesla to sign in."
        case .unknownExpiry(.owner):
            "The stored Owners API token has no expiration date."
        case .unknownExpiry(.fleet):
            "The stored Fleet API token has no expiration date."
        }
    }
}
