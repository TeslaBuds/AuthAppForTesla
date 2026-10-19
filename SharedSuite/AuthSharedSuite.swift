//
//  AuthSharedSuite.swift
//  Compiled into the apps and the widget extensions alike.
//

import Foundation

/// The `group.global` App Group suite — the ONE place its name and the token
/// summary's keys are spelled (pass 3, single owner).
///
/// The app writes the token summary here (`TokenSummaryPublisher`) and the
/// widget reads it (`TokenSummaryStore`); each used to carry its own copy of
/// the suite name and the four keys, so a rename on one side would have left
/// the widget reading keys nobody writes. Both now compile this file. The
/// app's settings live in the same suite (`UserDefaults.standard` is
/// redirected to it in `Util.swift`).
enum AuthSharedSuite {
    static let suiteName = "group.global"

    /// The suite, or `nil` if it cannot be opened.
    static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    /// What the app publishes for the widget: an expiry date and a presence
    /// flag per API, nothing else.
    enum TokenSummaryKey {
        static let ownersExpiresAt = "widget.tokenV3.expiresAt"
        static let ownersHasToken = "widget.tokenV3.hasToken"
        static let fleetExpiresAt = "widget.tokenV4.expiresAt"
        static let fleetHasToken = "widget.tokenV4.hasToken"
    }
}
