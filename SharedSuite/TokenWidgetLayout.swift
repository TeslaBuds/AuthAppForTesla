//
//  TokenWidgetLayout.swift
//  Compiled into the apps and the widget extensions alike.
//
//  Which layout the token widget draws in each size (Kemmey/DRSFramer#71:
//  every widget in every size, unless a size genuinely makes no sense).
//  The decision is a value so the app's unit tests can assert it; the widget
//  view switches over it exhaustively.
//

import WidgetKit

/// The token widget's layouts. Each size gets one that earns it: no size
/// shows a stretched smaller layout.
enum TokenWidgetLayout: Equatable, CaseIterable, Sendable {
    /// One API: the app mark, the urgency glyph and the hero expiry.
    case single
    /// Both APIs side by side, hero expiry each.
    case pair
    /// Both APIs as stacked cards with the hero expiry and the clock time.
    case cards
    /// Both APIs as side-by-side cards with the hero expiry and the clock time
    /// (the iPad and Mac extra-large tile, and the iOS 27 full page).
    case wideCards
    /// Lock Screen circular: the API glyph over its urgency glyph.
    case circular
    /// Lock Screen rectangular: one line per API with its clock time.
    case rectangular
    /// Lock Screen inline: the soonest-expiring API and its clock time.
    case inline

    /// Every size the system offers this platform. Accessory (Lock Screen)
    /// families exist only on iOS; the full-page portrait tile from iOS 27.
    /// No size is left out.
    static var families: [WidgetFamily] {
        #if os(iOS)
        var families: [WidgetFamily] = [
            .systemSmall, .systemMedium, .systemLarge, .systemExtraLarge,
            .accessoryCircular, .accessoryRectangular, .accessoryInline
        ]
        if #available(iOS 27.0, *) {
            families.append(.systemExtraLargePortrait)
        }
        return families
        #else
        return [.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge]
        #endif
    }

    init(family: WidgetFamily) {
        switch family {
        case .systemSmall: self = .single
        case .systemMedium: self = .pair
        case .systemLarge: self = .cards
        case .systemExtraLarge: self = .wideCards
        #if os(iOS)
        case .systemExtraLargePortrait: self = .wideCards
        #endif
        case .accessoryCircular: self = .circular
        case .accessoryRectangular: self = .rectangular
        case .accessoryInline: self = .inline
        // A family added by a later SDK: the most compact layout that holds both APIs.
        @unknown default: self = .pair
        }
    }
}
