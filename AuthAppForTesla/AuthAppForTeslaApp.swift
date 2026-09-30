//
//  AuthAppForTeslaApp.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import SwiftUI
import TeslaAuthKit

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
        // The size an iPad opens a new window at, as before. The Mac is
        // the native AuthAppForTeslaMac app since 3.1 (#44), so the old
        // Catalyst sizing and menu surgery are gone.
        .defaultSize(width: 940, height: 1080)
        .windowResizability(.contentSize)
        .commands {
            AppCommands(model: model)
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
