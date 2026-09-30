//
//  TokenSummaryStore.swift
//  AuthForTeslaWidgets
//

import Foundation

/// Read-only access to the token summary the app publishes for the widget.
///
/// The app writes these keys in `AuthViewModel.persistTokenSummary()` to the
/// `group.global` UserDefaults suite: an expiry date and a presence flag per
/// API, nothing else. The widget never touches the keychain and never writes
/// here, so it cannot alter the synced token list.
struct TokenSummaryStore {
    static let suiteName = "group.global"

    enum Key {
        static let ownersExpiresAt = "widget.tokenV3.expiresAt"
        static let ownersHasToken = "widget.tokenV3.hasToken"
        static let fleetExpiresAt = "widget.tokenV4.expiresAt"
        static let fleetHasToken = "widget.tokenV4.hasToken"
    }

    let defaults: UserDefaults?

    init(defaults: UserDefaults? = UserDefaults(suiteName: Self.suiteName)) {
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
