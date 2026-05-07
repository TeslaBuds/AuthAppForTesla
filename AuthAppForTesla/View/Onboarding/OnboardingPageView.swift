//
//  OnboardingPageView.swift
//  AuthAppForTesla
//

import SwiftUI

/// A single illustrated page in the onboarding flow.
struct OnboardingPageView: View {
    let systemImage: String
    let imageColor: Color
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: AppSpacing.lg) {
            Spacer()

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
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, AppSpacing.xl)

            Spacer()
        }
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
