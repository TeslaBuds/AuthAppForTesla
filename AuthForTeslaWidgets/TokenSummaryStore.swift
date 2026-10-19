//
//  TokenSummaryStore.swift
//  AuthForTeslaWidgets
//

import Foundation

/// Read-only access to the token summary the app publishes for the widget.
///
/// The app writes these keys with `TokenSummaryPublisher` (only on change) to the
/// `group.global` UserDefaults suite: an expiry date and a presence flag per
/// API, nothing else. The widget never touches the keychain and never writes
/// here, so it cannot alter the synced token list.
struct TokenSummaryStore {
    static let suiteName = AuthSharedSuite.suiteName

    /// The app's own spelling of the keys (`AuthSharedSuite`), never a copy.
    typealias Key = AuthSharedSuite.TokenSummaryKey

    let defaults: UserDefaults?

    init(defaults: UserDefaults? = AuthSharedSuite.defaults) {
        self.defaults = defaults
    }

    /// The current summary, stamped with `date`.
    func entry(at date: Date = .now) -> TokenWidgetEntry {
        TokenWidgetEntry(
            date: date,
            owners: status(hasToken: Key.ownersHasToken, expiresAt: Key.ownersExpiresAt),
            fleet: status(hasToken: Key.fleetHasToken, expiresAt: Key.fleetExpiresAt)
        )
    }

    private func status(hasToken: String, expiresAt: String) -> TokenStatus {
        guard defaults?.bool(forKey: hasToken) == true else { return .signedOut }
        return .signedIn(expiresAt: defaults?.object(forKey: expiresAt) as? Date)
    }
}
