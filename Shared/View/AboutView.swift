//
//  AboutView.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI
import TeslaAuthKit

struct AboutView: View {
    @State private var scrollPosition = ScrollPosition()

    var body: some View {
        IconBackgroundView {
            ScrollView {
                VStack(spacing: AppSpacing.cardGap) {
                    AboutViewHeader()
                    AboutViewShortcuts()
                    AboutViewMoreApps()
                        .id(AboutViewMoreApps.scrollID)
                    AboutViewFooter()
                    if !TipJarView.isSuppressed {
                        TipJarView(scrollPosition: $scrollPosition)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, AppSpacing.screenEdge)
                .padding(.top, AppSpacing.scrollTop)
                .padding(.bottom, AppSpacing.scrollBottom)
            }
            .scrollPosition($scrollPosition)
#if DEBUG
            .task {
                // Capture harness: `about-scroll-apps` scrolls to the app
                // grids so their layout can be photographed as presented.
                let args = CommandLine.arguments
                guard args.contains("about-scroll-apps") || args.contains("-about-scroll-apps") else { return }
                try? await Task.sleep(for: .seconds(1))
                scrollPosition.scrollTo(id: AboutViewMoreApps.scrollID, anchor: .top)
            }
#endif
        }
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
