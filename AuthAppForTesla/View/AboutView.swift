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
                AboutViewHeader()
                Spacer()
                AboutViewShortcuts()
                    .padding(.vertical)
                AboutViewMoreApps()
                AboutViewFooter()
                TipJarView(scrollPosition: $scrollPosition)
                    .padding(.bottom)
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
