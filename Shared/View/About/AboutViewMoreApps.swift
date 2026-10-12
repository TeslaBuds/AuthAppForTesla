//
//  AboutViewMoreApps.swift
//  AuthAppForTesla
//

import SwiftUI
import RumskrotAppsKit

/// "More from Dansk Rumskrot": every Dansk Rumskrot app that is live on the
/// App Store, with no curation (#62).
///
/// The list and the tap come from RumskrotAppsKit, like every other app in
/// the family. The list is `RumskrotApps.siblings`, which is every directory
/// app with an App Store ID except this one, so a new release appears here
/// with the next package bump and no edit. A tap goes through
/// `RumskrotAppStoreLink`, which opens Apple's store sheet in the app: modal
/// on iPhone and iPad, and a closable window on the Mac. The look is Auth's
/// own: the glass card and tile grid that "Friends of the App" uses, not
/// BrandKit's rows (Auth is exempt from BrandKit).
struct AboutViewMoreApps: View {
    /// Stable identity for scroll targeting.
    static let scrollID = "moreApps"
    static let title = "More from Dansk Rumskrot"

    /// The apps shown, in RumskrotAppsKit's directory order.
    static func apps(currentBundleID: String = Bundle.main.bundleIdentifier ?? "") -> [RumskrotApp] {
        RumskrotApps.siblings(currentBundleID: currentBundleID)
    }

    private let apps = AboutViewMoreApps.apps()

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Text(verbatim: Self.title)
                .font(.title)
                .accessibilityAddTraits(.isHeader)
            AboutTileGrid(itemCount: apps.count) {
                ForEach(apps) { app in
                    AboutMoreAppsTile(app: app)
                }
            }
        }
        .padding(AppSpacing.cardInner)
        .glassEffect(.clear, in: .rect(cornerRadius: AppCornerRadius.container))
    }
}

/// One app's tile. Opens the app's App Store page in the app.
private struct AboutMoreAppsTile: View {
    let app: RumskrotApp

    var body: some View {
        RumskrotAppStoreLink(app: app) {
            AboutTileLabel(name: app.shortName, tagline: app.tagline) { side in
                RumskrotAppIconImage(app: app, side: side)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: app.name))
        .accessibilityHint(Text(verbatim: app.tagline))
        .accessibilityIdentifier("moreApps.\(app.id)")
    }
}

#Preview {
    ScrollView {
        AboutViewMoreApps()
            .padding()
    }
}

#Preview("DRS + Friends side-by-side") {
    IconBackgroundView {
        ScrollView {
            VStack(spacing: AppSpacing.cardGap) {
                AboutViewMoreApps()
                AboutViewFooter()
            }
            .padding(.horizontal, AppSpacing.screenEdge)
        }
    }
}
