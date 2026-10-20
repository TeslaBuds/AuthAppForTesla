//
//  OnboardingPageView.swift
//  AuthAppForTesla
//

import SwiftUI
import TeslaAuthKit

/// A single illustrated page in the onboarding flow.
struct OnboardingPageView: View {
    let systemImage: String
    let imageColor: Color
    let title: String
    let description: String

    #if os(iOS)
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    #endif

    var body: some View {
        // Side by side when the height is compact (an iPhone in landscape,
        // the iPhone Duo's outer display turned), stacked otherwise — a
        // size-class decision, never the device type (#66).
        let layout = isHeightCompact
            ? AnyLayout(HStackLayout(spacing: AppSpacing.lg))
            : AnyLayout(VStackLayout(spacing: AppSpacing.lg))
        VStack(spacing: AppSpacing.lg) {
            Spacer(minLength: 0)
            layout {
                Image(systemName: systemImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 90, height: 90)
                    .foregroundStyle(imageColor)
                    .padding(AppSpacing.lg)
                    .background(imageColor.opacity(0.12), in: .circle)

                VStack(spacing: AppSpacing.sm) {
                    Text(title)
                        .font(.title2)
                        .bold()
                        .multilineTextAlignment(isHeightCompact ? .leading : .center)
                        .frame(maxWidth: .infinity, alignment: isHeightCompact ? .leading : .center)

                    Text(description)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(isHeightCompact ? .leading : .center)
                        .frame(maxWidth: .infinity, alignment: isHeightCompact ? .leading : .center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.horizontal, AppSpacing.xl)
            Spacer(minLength: 0)
        }
    }

    private var isHeightCompact: Bool {
        #if os(iOS)
        verticalSizeClass == .compact
        #else
        false
        #endif
    }
}

#Preview {
    OnboardingPageView(
        systemImage: "key.fill",
        imageColor: Color("TeslaRed"),
        title: "Your Tesla, Your Tokens",
        description: "Auth for Tesla securely fetches OAuth tokens for your Tesla account so other apps and automations can work with your vehicles."
    )
}
