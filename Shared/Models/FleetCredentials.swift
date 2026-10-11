//
//  FleetCredentials.swift
//  AuthAppForTesla
//
//  The developer's Fleet API client credentials, as typed into the
//  sign-in form or Mac Settings.
//

import Foundation
import Security
import TeslaAuthKit

/// The Fleet API client ID, secret and redirect URI, trimmed of the
/// stray spaces and line breaks a paste from developer.tesla.com brings
/// along (#53).
struct FleetCredentials: Equatable, Sendable {
    let clientId: String
    let clientSecret: String
    let redirectUri: String

    init(clientId: String, clientSecret: String, redirectUri: String) {
        self.clientId = clientId.trimmingCharacters(in: .whitespacesAndNewlines)
        self.clientSecret = clientSecret.trimmingCharacters(in: .whitespacesAndNewlines)
        self.redirectUri = redirectUri.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The keychain keys, in the order they are written.
    static let keys = [kFleetClientID, kFleetClientSecret, kFleetRedirectUri]

    /// Each value with the keychain key it is stored under.
    var items: [(key: String, value: String)] {
        [(kFleetClientID, clientId), (kFleetClientSecret, clientSecret), (kFleetRedirectUri, redirectUri)]
    }

    /// Stores the credentials, behind the sync-wipe guard (#44): when any
    /// of the three synced items cannot be read on this device, nothing
    /// is written and the reason is thrown instead of claiming success
    /// (#54).
    func store(
        read: (String) -> KeychainReadResult,
        write: (_ value: String, _ key: String) -> Bool
    ) throws(TokenStoreError) {
        for key in Self.keys {
            if case .failed(let status) = read(key) { throw .unreadable(status) }
        }
        for item in items where !write(item.value, item.key) {
            throw .writeFailed(errSecIO)
        }
    }
}
