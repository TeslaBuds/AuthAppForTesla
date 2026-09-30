//
//  AboutViewFooter.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI
import TeslaAuthKit

struct AboutViewFooter: View {
    /// Shuffled once per appearance, not per render: the grid re-lays out
    /// on every window resize and must not reorder the tiles while it does.
    @State private var friends = [
        Friend(name: "TeSlate", appId: "1532406445", appUrl: nil, icon: "TeSlate"),
        Friend(name: "Teslascope", appId: nil, appUrl: "https://teslascope.com", icon: "TeslaScope"),
        Friend(name: "Tesla iOS Shortcuts", appId: nil, appUrl: "https://github.com/dburkland/tesla_ios_shortcuts/blob/master/README.md", icon: "tesla_ios_shortcuts"),
        Friend(name: "Autarkie Manager", appId: "1518598578", appUrl: nil, icon: "AutarkieManager"),
    ].shuffled()

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Text("Friends of the App")
                .font(.title)
            AboutTileGrid(itemCount: friends.count) {
                ForEach(friends, id: \.name) { friend in
                    AboutViewFriend(name: friend.name, appId: friend.appId, appUrl: friend.appUrl, icon: friend.icon)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(AppSpacing.cardInner)
        .glassEffect(.clear, in: .rect(cornerRadius: AppCornerRadius.container))
    }
}

struct Friend {
    let name: String
    let appId: String?
    let appUrl: String?
    let icon: String
    /// Optional one-line description shown under the name.
    var tagline: String? = nil
}

#Preview {
    AboutViewFooter()
}
