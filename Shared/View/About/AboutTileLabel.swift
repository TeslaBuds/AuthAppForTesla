//
//  AboutTileLabel.swift
//  AuthAppForTesla
//

import SwiftUI

/// The face of one About tile: a 60-point icon, the name and an optional
/// one-line tagline. "More from Dansk Rumskrot" and "Friends of the App"
/// both draw their tiles with it, so the two grids look the same.
struct AboutTileLabel<Icon: View>: View {
    let name: String
    var tagline: String? = nil
    /// Draws the icon at the side it is given.
    @ViewBuilder let icon: (CGFloat) -> Icon

    /// The icon's side, scaled with Dynamic Type.
    @ScaledMetric(relativeTo: .subheadline) private var iconSide: CGFloat = 60

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            icon(iconSide)
                .frame(width: iconSide, height: iconSide)
                .accessibilityHidden(true)
            Text(verbatim: name)
                .font(.subheadline)
            if let tagline {
                Text(verbatim: tagline)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .multilineTextAlignment(.center)
        .padding(AppSpacing.sm)
        .contentShape(.rect)
        .shadow(radius: AppTheme.shadowRadius)
    }
}
