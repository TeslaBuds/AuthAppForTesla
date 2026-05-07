//
//  AboutView.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI

struct AboutView: View {
    @State private var scrollPosition = ScrollPosition()

    var body: some View {
        IconBackgroundView {
            ScrollView {
                VStack(spacing: AppSpacing.cardGap) {
                    AboutViewHeader()
                    AboutViewShortcuts()
                    AboutViewMoreApps()
                    AboutViewFooter()
                    TipJarView(scrollPosition: $scrollPosition)
                }
                .padding(.horizontal, AppSpacing.screenEdge)
                .padding(.top, AppSpacing.scrollTop)
                .padding(.bottom, AppSpacing.scrollBottom)
            }
            .scrollPosition($scrollPosition)
        }
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
