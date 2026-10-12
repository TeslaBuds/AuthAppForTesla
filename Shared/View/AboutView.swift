//
//  AboutView.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI
import TeslaAuthKit
import RumskrotAppsKit

struct AboutView: View {
    @State private var scrollPosition = ScrollPosition()
#if DEBUG
    /// Capture harness: `about-open-beta` lands on the beta screen.
    @State private var showsBetaForCapture = CommandLine.arguments.contains("about-open-beta")
        || CommandLine.arguments.contains("-about-open-beta")
#endif

    var body: some View {
        IconBackgroundView {
            ScrollView {
                VStack(spacing: AppSpacing.cardGap) {
                    AboutViewHeader()
                    AboutViewShortcuts()
                    // The suite's Settings ending: the beta invitation, then
                    // More from Dansk Rumskrot (audit §4.1).
                    AboutViewBeta()
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
            .navigationDestination(isPresented: $showsBetaForCapture) {
                if let program = BetaProgram(bundleID: Bundle.main.bundleIdentifier ?? "") {
                    AuthBetaProgramView(program: program)
                }
            }
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
