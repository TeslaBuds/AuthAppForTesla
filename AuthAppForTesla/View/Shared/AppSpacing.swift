//
//  AppSpacing.swift
//  AuthAppForTesla
//
//  Single source of truth for vertical and horizontal spacing across
//  every screen. Use the named tokens below instead of dropping
//  magic numbers into `.padding(...)` / `VStack(spacing: ...)` so
//  the rhythm stays consistent and we can grep for "AppSpacing" to
//  audit (or globally retune) the look.
//
//  The scale is the standard Apple 4pt grid (4 / 8 / 16 / 24 / 32),
//  with a few semantic constants for screen-relative concerns where
//  we want the *meaning* of the value to be visible at the call site
//  rather than just a number.
//

import SwiftUI

/// Numeric spacing tokens. Keep additions on the 4pt grid.
enum AppSpacing {
    /// 4pt — tightest grouping (icon ↔ label, badge inner gutter).
    static let xs: CGFloat = 4
    /// 8pt — items inside a row, related controls.
    static let sm: CGFloat = 8
    /// 16pt — Apple's default. Card inner padding, body line gap,
    /// and the standard horizontal margin from screen edges.
    static let md: CGFloat = 16
    /// 24pt — gap between major sections in a scroll view, between
    /// page title and first card.
    static let lg: CGFloat = 24
    /// 32pt — major region break (e.g. above a footer-style block).
    static let xl: CGFloat = 32

    // MARK: - Screen-relative semantic spacing

    /// Horizontal margin from screen edges to a card's outer edge.
    /// Matches `.padding(.horizontal)` (= md = 16pt) so cards hug
    /// the safe area symmetrically.
    static let screenEdge: CGFloat = md

    /// Vertical padding above the first card in a scroll view's
    /// content. Lets the page title or nav bar breathe instead of
    /// the first card crowding it.
    static let scrollTop: CGFloat = md

    /// Vertical padding below the last card in a scroll view's
    /// content. Sized so content clears the floating tab bar
    /// capsule with a comfortable margin.
    static let scrollBottom: CGFloat = lg

    /// Vertical gap between stacked cards inside a scroll view.
    /// Matches HomeView's existing rhythm.
    static let cardGap: CGFloat = md

    /// Inner padding inside a glass card. The .glassCard() helper
    /// in IconBackgroundView already applies `.padding()` (= 16pt),
    /// so views that build their own card should match.
    static let cardInner: CGFloat = md

    /// Bottom inset needed to clear the iOS 26 floating tab bar
    /// capsule (≈75pt tall, with margins). Used for elements that
    /// float at the bottom of the screen on top of the TabView,
    /// like the toast overlay.
    static let tabBarClearance: CGFloat = 110
}

/// Corner radius tokens, shared across glass cards, buttons, and
/// other rounded surfaces.
enum AppCornerRadius {
    /// 12pt — small chips, compact pills.
    static let small: CGFloat = 12
    /// 16pt — standard cards.
    static let card: CGFloat = 16
    /// 24pt — full-width container with glass effect (matches
    /// the .glassCard() helper).
    static let container: CGFloat = 24
}
