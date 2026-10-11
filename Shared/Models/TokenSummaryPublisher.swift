//
//  TokenSummaryPublisher.swift
//  AuthAppForTesla
//
//  #58: the widget summary is written, and the widget reloaded, only when
//  what the widget shows actually changed.
//

import Foundation
import TeslaAuthKit
import WidgetKit

/// What the widget shows: per API, whether there is a token and when it
/// expires. Nothing secret.
struct TokenSummary: Equatable, Sendable {
    var hasOwnersToken: Bool
    var ownersExpiresAt: Date?
    var hasFleetToken: Bool
    var fleetExpiresAt: Date?

    init(hasOwnersToken: Bool, ownersExpiresAt: Date?, hasFleetToken: Bool, fleetExpiresAt: Date?) {
        self.hasOwnersToken = hasOwnersToken
        self.ownersExpiresAt = ownersExpiresAt
        self.hasFleetToken = hasFleetToken
        self.fleetExpiresAt = fleetExpiresAt
    }

    init(owners: Token?, fleet: Token?) {
        self.init(hasOwnersToken: owners != nil, ownersExpiresAt: owners?.expires_at,
                  hasFleetToken: fleet != nil, fleetExpiresAt: fleet?.expires_at)
    }
}

/// Writes the token summary to the App Group suite the widget reads
/// (`AuthForTeslaWidgets/TokenSummaryStore`), and reloads the widget's
/// timeline — but only when the stored summary differs.
///
/// The comparison is against what is stored in the suite, not against an
/// in-memory copy, so a summary written by another process (a Shortcut,
/// #52) is respected and never causes a redundant reload here.
struct TokenSummaryPublisher {
    static let suiteName = "group.global"

    /// The keys `TokenSummaryStore` in the widget extension reads.
    enum Key {
        static let ownersExpiresAt = "widget.tokenV3.expiresAt"
        static let ownersHasToken = "widget.tokenV3.hasToken"
        static let fleetExpiresAt = "widget.tokenV4.expiresAt"
        static let fleetHasToken = "widget.tokenV4.hasToken"
    }

    /// The widget's kind, from `AuthForTeslaWidgets/TokenWidget.swift`.
    static let widgetKind = "TokenWidget"

    let defaults: UserDefaults?
    let reloadWidget: @Sendable () -> Void

    init(defaults: UserDefaults?, reloadWidget: @escaping @Sendable () -> Void) {
        self.defaults = defaults
        self.reloadWidget = reloadWidget
    }

    /// The real App Group suite and the real widget.
    static var live: TokenSummaryPublisher {
        TokenSummaryPublisher(defaults: UserDefaults(suiteName: suiteName)) {
            WidgetCenter.shared.reloadTimelines(ofKind: widgetKind)
        }
    }

    /// The summary currently stored in the suite, or nil without a suite.
    var stored: TokenSummary? {
        guard let defaults else { return nil }
        return TokenSummary(
            hasOwnersToken: defaults.bool(forKey: Key.ownersHasToken),
            ownersExpiresAt: defaults.object(forKey: Key.ownersExpiresAt) as? Date,
            hasFleetToken: defaults.bool(forKey: Key.fleetHasToken),
            fleetExpiresAt: defaults.object(forKey: Key.fleetExpiresAt) as? Date
        )
    }

    /// Stores `summary` and reloads the widget, unless that is already
    /// what is stored. Returns whether anything was written.
    @discardableResult
    func publish(_ summary: TokenSummary) -> Bool {
        guard let defaults, stored != summary else { return false }
        defaults.set(summary.ownersExpiresAt, forKey: Key.ownersExpiresAt)
        defaults.set(summary.fleetExpiresAt, forKey: Key.fleetExpiresAt)
        defaults.set(summary.hasOwnersToken, forKey: Key.ownersHasToken)
        defaults.set(summary.hasFleetToken, forKey: Key.fleetHasToken)
        reloadWidget()
        return true
    }
}
