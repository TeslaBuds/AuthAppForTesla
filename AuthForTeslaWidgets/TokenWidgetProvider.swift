//
//  TokenWidgetProvider.swift
//  AuthForTeslaWidgets
//

import Foundation
import WidgetKit

/// Builds the widget's timeline from the app's token summary.
///
/// The app reloads the timelines whenever a token changes. Between reloads,
/// the timeline carries an entry for each moment a token turns "expiring
/// soon" or "expired", so the colour changes on time without a refresh.
struct TokenWidgetProvider: TimelineProvider {
    var store = TokenSummaryStore()

    func placeholder(in context: Context) -> TokenWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping @Sendable (TokenWidgetEntry) -> Void) {
        completion(context.isPreview ? .placeholder : store.entry())
    }

    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<TokenWidgetEntry>) -> Void) {
        completion(Self.timeline(for: store.entry()))
    }

    /// One entry now, plus one at every later urgency change.
    static func timeline(for entry: TokenWidgetEntry) -> Timeline<TokenWidgetEntry> {
        let changes = Set(entry.owners.transitions(after: entry.date) + entry.fleet.transitions(after: entry.date))
        let entries = [entry] + changes.sorted().map(entry.at)
        return Timeline(entries: entries, policy: .never)
    }
}
