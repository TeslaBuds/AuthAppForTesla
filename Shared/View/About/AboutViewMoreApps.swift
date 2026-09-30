//
//  AboutViewMoreApps.swift
//  AuthAppForTesla
//

import SwiftUI
import TeslaAuthKit

/// Cross-promotes other Dansk Rumskrot apps. Mirrors the Friends grid
/// but uses our own apps and our own copy.
struct AboutViewMoreApps: View {
    /// Stable identity for scroll targeting.
    static let scrollID = "moreApps"

    /// Every Dansk Rumskrot app that is live on the App Store (checked
    /// against the public App Store lookup on 29 Sep 2026, #43). Apps still
    /// in review are left out until they ship. No prices here, by design.
    private let apps: [Friend] = [
        Friend(name: "Caravan Leveler", appId: "1537330412", appUrl: nil, icon: "CaravanLeveler",
               tagline: "Level your caravan or camper"),
        Friend(name: "ManaScope", appId: "6760581915", appUrl: nil, icon: "ManaScope",
               tagline: "Scan and collect Magic cards"),
        Friend(name: "PairPanic", appId: "6761368630", appUrl: nil, icon: "PairPanic",
               tagline: "A fast symbol-matching game"),
        Friend(name: "Rumskrot Beacon", appId: "6766202612", appUrl: nil, icon: "RumskrotBeacon",
               tagline: "Find where your network breaks"),
        Friend(name: "Rumskrot Pulse", appId: "6766450592", appUrl: nil, icon: "RumskrotPulse",
               tagline: "Bluetooth LE debugger"),
        Friend(name: "Rumskrot Remote", appId: "6761122209", appUrl: nil, icon: "RumskrotRemote",
               tagline: "Your Mac's screen, anywhere"),
        Friend(name: "Rumskrot Terminal", appId: "6761121988", appUrl: nil, icon: "RumskrotTerminal",
               tagline: "An SSH terminal for your servers"),
    ]

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Text("More from Dansk Rumskrot")
                .font(.title)
            AboutTileGrid(itemCount: apps.count) {
                ForEach(apps, id: \.name) { app in
                    AboutViewFriend(name: app.name, appId: app.appId, appUrl: app.appUrl, icon: app.icon, tagline: app.tagline)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(AppSpacing.cardInner)
        .glassEffect(.clear, in: .rect(cornerRadius: AppCornerRadius.container))
    }
}

#Preview {
    AboutViewMoreApps()
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
