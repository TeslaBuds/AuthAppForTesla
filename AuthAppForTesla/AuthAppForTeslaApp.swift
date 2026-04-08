//
//  AuthAppForTeslaApp.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import SwiftUI

@main
struct AuthAppForTeslaApp: App {
    @State private var model = AuthViewModel()

    init() {
        #if DEBUG
        // Live UI tests launch the app with this argument so every run
        // starts from a guaranteed clean state. We have to write to
        // UserDefaults BEFORE the view hierarchy is created, otherwise
        // RootView reads the old @AppStorage("hasSeenOnboarding") value
        // and presents the onboarding sheet which then occludes every
        // other view in the test's accessibility tree.
        if CommandLine.arguments.contains("live-test-clear-state") {
            UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
        }
        #endif
    }

    var body: some Scene {
        WindowGroup {
            RootView(model: model, initialTab: initialTab)
                // On Mac Catalyst the user can resize the window freely,
                // and SwiftUI happily lets them shrink it down to a few
                // dozen points wide, at which point the layout collapses
                // into one-word-per-line. Apply a sane content-driven
                // minimum so .windowResizability(.contentSize) below
                // adopts it as the actual window minimum size. The
                // width is high enough that the four-tab title bar
                // never collapses into the popup picker.
                #if targetEnvironment(macCatalyst)
                .frame(minWidth: 940, minHeight: 760)
                #endif
                .task {
                    #if DEBUG
                    if ScreenshotScenario.isActive {
                        await ScreenshotHarness.seed(model: model)
                        return
                    }
                    // The live UI test target launches with this arg so
                    // every test starts from a clean keychain — no
                    // leftover profiles from a previous run.
                    if CommandLine.arguments.contains("live-test-clear-state") {
                        await AuthController.shared.wipeAllProfiles()
                    }
                    #endif
                    await model.loadTokens()
                    await downloadLatestExternalApplicationList()
                }
        }
        // The app is fundamentally a phone-shaped column of token cards.
        // On Mac Catalyst we want it to open at a comfortable size that
        // fits the four-tab title bar SwiftUI renders. Catalyst applies
        // iPad-to-Mac scaling (~0.77x) on top of this value, so 940 here
        // renders as roughly 720pt of visual width — wide enough that
        // the tab bar doesn't collapse into a popup picker.
        // `.contentSize` lets the user resize freely from there but
        // respects the content minimum frame above.
        .defaultSize(width: 940, height: 1080)
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(after: .sidebar) {
                Button("Refresh All Tokens", systemImage: "arrow.clockwise") {
                    model.refreshAll()
                }
                .keyboardShortcut("r", modifiers: .command)
            }
        }
    }

    private var initialTab: AppTab {
        #if DEBUG
        return ScreenshotHarness.initialTab()
        #else
        return .owners
        #endif
    }
}
