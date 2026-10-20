//
//  OnboardingPageDots.swift
//  AuthAppForTesla
//

import SwiftUI
import TeslaAuthKit

/// The onboarding page indicator. It sits in the layout below the pages,
/// never over them, so on a short display (the iPhone Duo's outer
/// display, an iPhone in landscape, large text) it cannot cover the last
/// lines of a page or the Continue button (#66).
struct OnboardingPageDots: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            ForEach(0..<count, id: \.self) { index in
                Circle()
                    .fill(index == current ? Color.primary : Color.secondary.opacity(0.4))
                    .frame(width: 7, height: 7)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(current + 1) of \(count)")
    }
}

#Preview {
    OnboardingPageDots(count: 3, current: 1)
}
