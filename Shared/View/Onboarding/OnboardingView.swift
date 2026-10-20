//
//  OnboardingView.swift
//  AuthAppForTesla
//

import SwiftUI
import TeslaAuthKit

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
            #if os(macOS)
            // A Mac window has no swipeable page view: one page at a time,
            // advanced by the button, with the same dots below it.
            let page = pages[currentPage]
            OnboardingPageView(
                systemImage: page.systemImage,
                imageColor: page.color,
                title: page.title,
                description: page.description
            )
            .id(currentPage)
            .transition(.push(from: .trailing))
            #else
            // A paging scroll view rather than a `.page` TabView: TabView
            // draws its dots over the page, and on a short display (the
            // iPhone Duo's outer display, landscape, large text) they
            // covered the text. Each page scrolls vertically on its own,
            // so nothing is clipped whatever the height (#66).
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(pages.indices, id: \.self) { index in
                        let page = pages[index]
                        ScrollView {
                            OnboardingPageView(
                                systemImage: page.systemImage,
                                imageColor: page.color,
                                title: page.title,
                                description: page.description
                            )
                        }
                        .defaultScrollAnchor(.center, for: .alignment)
                        .scrollBounceBehavior(.basedOnSize)
                        .containerRelativeFrame([.horizontal, .vertical])
                        .id(index)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollIndicators(.hidden)
            .scrollPosition(id: pagePosition)
            // A scroll view draws into the safe area beside it; without the
            // clip the next page peeks out under the iPhone Duo's camera
            // column on the outer display.
            .clipShape(.rect)
            .padding(.bottom, AppSpacing.md)
            #endif

            OnboardingPageDots(count: pages.count, current: currentPage)

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
            .accessibilityIdentifier("onboardingContinueButton")
            .buttonStyle(.borderedProminent)
            .tint(Color("TeslaRed"))
            .padding(.horizontal, AppSpacing.xl)
            .padding(.top, AppSpacing.md)
            .padding(.bottom, Self.bottomMargin)
            .animation(.default, value: currentPage)
        }
        .interactiveDismissDisabled()
    }

    /// Below the button. A sheet on iOS already keeps clear of the home
    /// indicator, so it needs less than a Mac window does.
    #if os(iOS)
    private static let bottomMargin = AppSpacing.lg
    #else
    private static let bottomMargin = AppSpacing.xl + AppSpacing.md
    #endif

    #if os(iOS)
    /// The paging scroll view's position, as the page number.
    private var pagePosition: Binding<Int?> {
        Binding(
            get: { currentPage },
            set: { if let page = $0 { currentPage = page } }
        )
    }
    #endif

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
