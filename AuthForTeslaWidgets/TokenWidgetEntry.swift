//
//  TokenWidgetEntry.swift
//  AuthForTeslaWidgets
//

import Foundation
import WidgetKit

/// Whether an API has a signed-in account, and when its access token expires.
enum TokenStatus: Equatable, Sendable {
    case signedOut
    case signedIn(expiresAt: Date?)

    /// How urgent the token looks at `date`.
    enum Urgency: Equatable, Sendable {
        case signedOut, valid, expiringSoon, expired
    }

    /// A token with less than this left is shown as expiring soon.
    static let expiringSoonInterval: TimeInterval = 3_600

    func urgency(at date: Date) -> Urgency {
        switch self {
        case .signedOut:
            return .signedOut
        case .signedIn(let expiresAt):
            guard let expiresAt else { return .valid }
            if expiresAt <= date { return .expired }
            if expiresAt.timeIntervalSince(date) < Self.expiringSoonInterval { return .expiringSoon }
            return .valid
        }
    }

    var expiresAt: Date? {
        if case .signedIn(let expiresAt) = self { expiresAt } else { nil }
    }

    /// The moments after `date` at which this token's urgency changes.
    func transitions(after date: Date) -> [Date] {
        guard let expiresAt else { return [] }
        return [expiresAt.addingTimeInterval(-Self.expiringSoonInterval), expiresAt]
            .filter { $0 > date }
    }
}

/// The data snapshot shown in a single widget render.
struct TokenWidgetEntry: TimelineEntry {
    let date: Date
    /// The Owners API (v3) access token of the active account.
    let owners: TokenStatus
    /// The Fleet API (v4) access token of the active account.
    let fleet: TokenStatus

    static let placeholder = TokenWidgetEntry(
        date: .now,
        owners: .signedIn(expiresAt: .now.addingTimeInterval(3_600 * 6)),
        fleet: .signedIn(expiresAt: .now.addingTimeInterval(3_600 * 7))
    )

    /// The same summary, re-evaluated at a later moment.
    func at(_ date: Date) -> TokenWidgetEntry {
        TokenWidgetEntry(date: date, owners: owners, fleet: fleet)
    }
}
