//
//  AboutTileGrid.swift
//  AuthAppForTesla
//

import SwiftUI
import TeslaAuthKit

/// The About screen's app-tile grid ("More from Dansk Rumskrot", "Friends of
/// the App"). It fills the width it is given and flows into as many columns
/// as fit, so a wide Mac window or an iPad shows one or two balanced rows
/// instead of a fixed two-column block stranded in the middle (#46).
struct AboutTileGrid<Content: View>: View {
    let itemCount: Int
    @ViewBuilder let content: () -> Content

    @State private var availableWidth: CGFloat = 0

    var body: some View {
        let count = AboutTileColumns.count(
            items: itemCount,
            width: availableWidth,
            minimumTileWidth: AboutTileColumns.minimumTileWidth,
            spacing: AppSpacing.sm
        )
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: AppSpacing.sm, alignment: .top), count: count),
            alignment: .center,
            spacing: AppSpacing.sm,
            content: content
        )
        .frame(maxWidth: .infinity)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.width
        } action: { width in
            availableWidth = width
        }
    }
}

/// How many columns the About tile grid uses at a given width.
enum AboutTileColumns {
    /// The narrowest a tile may get and still fit its name and tagline.
    static let minimumTileWidth: CGFloat = 140

    /// As many columns as fit, but balanced so the rows come out even:
    /// six tiles with room for four become two rows of three, not four
    /// and a straggling two. Never more columns than tiles, never fewer
    /// than two (the old fixed layout) unless there is only one tile.
    static func count(items: Int, width: CGFloat, minimumTileWidth: CGFloat, spacing: CGFloat) -> Int {
        guard items > 0 else { return 1 }
        let fitting = width > 0 ? Int((width + spacing) / (minimumTileWidth + spacing)) : 2
        let columns = min(items, max(2, fitting))
        let rows = (items + columns - 1) / columns
        return (items + rows - 1) / rows
    }
}

#Preview("Six tiles") {
    AboutViewMoreApps()
        .padding()
}
