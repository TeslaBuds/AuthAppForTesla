//
//  OnboardingView.swift
//  AuthAppForTesla
//

import SwiftUI

/// Three-step welcome sheet shown on first launch.
/// Dismissed by tapping "Get Started" or swiping down.
struct OnboardingView: View {
    @Binding var isPresented: Bool
    @State private var currentPage = 0

    private let pages: [(systemImage: String, color: Color, title: String, description: String)] = [
        (
            systemImage: "key.horizontal.fill",
            color: Color("TeslaRed"),
            title: "Your Tesla, Your Tokens",
            description: "Auth for Tesla fetches secure OAuth tokens for your Tesla account, unlocking third-party apps, automations, and more."
        ),
        (
            systemImage: "lock.shield.fill",
            color: Color("TeslaRed"),
            title: "Your Credentials Stay on Device",
            description: "Sign-in happens in a secure browser — your Tesla password never passes through this app. Tokens are stored in your iCloud Keychain and sync across your devices."
        ),
        (
            systemImage: "puzzlepiece.extension.fill",
            color: Color("TeslaRed"),
            title: "Works With the Apps You Love",
            description: "Tap a token to copy it to the clipboard, or use the built-in Shortcuts and Siri integration to automate token delivery to any app."
        )
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                ForEach(pages.indices, id: \.self) { index in
                    let page = pages[index]
                    OnboardingPageView(
                        systemImage: page.systemImage,
                        imageColor: page.color,
                        title: page.title,
                        description: page.description
                    )
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button {
                if currentPage < pages.count - 1 {
                    withAnimation {
                        currentPage += 1
                    }
                } else {
                    dismiss()
                }
            } label: {
                Text(currentPage == pages.count - 1 ? "Get Started" : "Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color("TeslaRed"))
            .padding(.horizontal, 32)
            .padding(.bottom, 48)
            .padding(.top, 16)
            .animation(.default, value: currentPage)
        }
        .interactiveDismissDisabled()
    }

    private func dismiss() {
        isPresented = false
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            OnboardingView(isPresented: .constant(true))
        }
}
