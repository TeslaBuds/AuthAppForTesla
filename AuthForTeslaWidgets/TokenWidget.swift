//
//  TokenWidget.swift
//  AuthForTeslaWidgets
//

import SwiftUI
import WidgetKit

/// Shows how long the active Owners API and Fleet API access tokens have
/// left. It shows expiry only, never a token, and it reads nothing but the
/// summary the app writes to the App Group (see `TokenSummaryStore`).
struct TokenWidget: Widget {
    static let kind = "TokenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: TokenWidgetProvider()) { entry in
            TokenWidgetView(entry: entry)
        }
        .configurationDisplayName("Token Expiry")
        .description("Shows how long your Owners API and Fleet API access tokens have left.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
