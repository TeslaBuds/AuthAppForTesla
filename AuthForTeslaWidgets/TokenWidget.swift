//
//  TokenWidget.swift
//  AuthForTeslaWidgets
//
//  This file is the entry point for the widget extension target.
//  To activate:
//  1. In Xcode: File > New > Target > Widget Extension
//  2. Name it "AuthForTeslaWidgets"
//  3. Add this folder's files to that target
//  4. In the widget target's entitlements, add App Group "group.global"
//  5. Set the widget target's deployment target to iOS 17 or later
//

import WidgetKit
import SwiftUI

/// Home- and Lock-screen widget showing token expiry status
/// with an interactive copy button (iOS 17+ interactive widgets).
struct TokenWidget: Widget {
    let kind = "TokenWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TokenWidgetProvider()) { entry in
            TokenWidgetView(entry: entry)
        }
        .configurationDisplayName("Auth for Tesla")
        .description("Shows Owners and Fleet API token expiry status.")
        .supportedFamilies([.systemSmall, .systemMedium])
        .contentMarginsDisabled()
    }
}

/// Widget bundle entry point — the single source of truth for all widgets
/// in this extension.
@main
struct AuthForTeslaWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TokenWidget()
    }
}
