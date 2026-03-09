//
//  TokenWidgetProvider.swift
//  AuthForTeslaWidgets
//
//  Add this file to the "AuthForTeslaWidgets" widget extension target.
//

import WidgetKit
import Foundation

/// Reads token expiry information from the shared App Group UserDefaults
/// (written by the main app via AuthViewModel.persistTokenSummary()).
struct TokenWidgetProvider: TimelineProvider {
    private let suiteName = "group.global"

    func placeholder(in context: Context) -> TokenWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (TokenWidgetEntry) -> Void) {
        completion(makeEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TokenWidgetEntry>) -> Void) {
        let entry = makeEntry()

        // Refresh shortly after the next token expiry, or in 30 minutes if none.
        let nextRefresh: Date
        let expiryDates = [entry.v3ExpiresAt, entry.v4ExpiresAt].compactMap { $0 }
        if let soonest = expiryDates.min() {
            nextRefresh = soonest.addingTimeInterval(60)
        } else {
            nextRefresh = .now.addingTimeInterval(1800)
        }

        let timeline = Timeline(entries: [entry], policy: .after(nextRefresh))
        completion(timeline)
    }

    private func makeEntry() -> TokenWidgetEntry {
        let defaults = UserDefaults(suiteName: suiteName)
        return TokenWidgetEntry(
            date: .now,
            v3HasToken: defaults?.bool(forKey: "widget.tokenV3.hasToken") ?? false,
            v3ExpiresAt: defaults?.object(forKey: "widget.tokenV3.expiresAt") as? Date,
            v4HasToken: defaults?.bool(forKey: "widget.tokenV4.hasToken") ?? false,
            v4ExpiresAt: defaults?.object(forKey: "widget.tokenV4.expiresAt") as? Date
        )
    }
}
