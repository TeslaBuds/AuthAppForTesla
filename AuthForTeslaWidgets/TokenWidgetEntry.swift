//
//  TokenWidgetEntry.swift
//  AuthForTeslaWidgets
//
//  Add this file to the "AuthForTeslaWidgets" widget extension target.
//

import WidgetKit
import Foundation

/// The data snapshot shown in a single widget render.
struct TokenWidgetEntry: TimelineEntry {
    let date: Date

    // Owners API (v3)
    let v3HasToken: Bool
    let v3ExpiresAt: Date?

    // Fleet API (v4)
    let v4HasToken: Bool
    let v4ExpiresAt: Date?

    static let placeholder = TokenWidgetEntry(
        date: .now,
        v3HasToken: true,
        v3ExpiresAt: .now.addingTimeInterval(3600 * 6),
        v4HasToken: false,
        v4ExpiresAt: nil
    )
}
