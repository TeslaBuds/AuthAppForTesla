//
//  AboutViewMoreApps.swift
//  AuthAppForTesla
//

import SwiftUI

/// Cross-promotes other Dansk Rumskrot apps. Mirrors the Friends grid
/// but uses our own apps and our own copy.
struct AboutViewMoreApps: View {
    private var columns: [GridItem] = [
        GridItem(.fixed(150), spacing: AppSpacing.sm),
        GridItem(.fixed(150), spacing: AppSpacing.sm),
    ]

    private let apps: [Friend] = [
        Friend(name: "ManaScope", appId: "6760581915", appUrl: nil, icon: "ManaScope"),
        Friend(name: "PairPanic", appId: "6761368630", appUrl: nil, icon: "PairPanic"),
        Friend(name: "Rumskrot Remote", appId: "6761122209", appUrl: nil, icon: "RumskrotRemote"),
        Friend(name: "Rumskrot Terminal", appId: "6761121988", appUrl: nil, icon: "RumskrotTerminal"),
    ]

    var body: some View {
#if !targetEnvironment(macCatalyst)
        VStack(spacing: AppSpacing.sm) {
            Text("More from Dansk Rumskrot")
                .font(.title)
            LazyVGrid(
                columns: columns,
                alignment: .center,
                spacing: 0
            ) {
                ForEach(apps, id: \.name) { app in
                    AboutViewFriend(name: app.name, appId: app.appId, appUrl: app.appUrl, icon: app.icon)
                        .frame(height: 140, alignment: .top)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(AppSpacing.cardInner)
        .glassEffect(.clear, in: .rect(cornerRadius: AppCornerRadius.container))
#else
        EmptyView()
#endif
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
