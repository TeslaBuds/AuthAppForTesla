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

    var body: some Scene {
        WindowGroup {
            RootView(model: model, initialTab: initialTab)
                .task {
                    #if DEBUG
                    if ScreenshotScenario.isActive {
                        await ScreenshotHarness.seed(model: model)
                        return
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
        // `.contentSize` lets the user resize freely from there.
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
