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
    }

    private var initialTab: AppTab {
        #if DEBUG
        return ScreenshotHarness.initialTab()
        #else
        return .owners
        #endif
    }
}
