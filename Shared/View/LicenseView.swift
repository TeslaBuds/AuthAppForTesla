//
//  LicenseView.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI
import TeslaAuthKit

struct LicenseView: View {
    var body: some View {
        IconBackgroundView {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(OpenSourceComponent.allCases, id: \.self) { component in
                        if component != OpenSourceComponent.allCases.first {
                            Divider()
                        }
                        LicenseViewEntry(component: component)
                    }
                }
                .glassEffect(.clear, in: .rect(cornerRadius: AppCornerRadius.container))
                .padding(.horizontal, AppSpacing.screenEdge)
                .padding(.top, AppSpacing.scrollTop)
                .padding(.bottom, AppSpacing.scrollBottom)
            }
            .navigationTitle("Open Source Licenses")
            .inlineNavigationTitle()
        }
    }
}

#Preview {
    LicenseView()
}
