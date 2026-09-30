//
//  MacLaunch.swift
//  AuthAppForTeslaMac
//
//  What the Mac does once at launch, the same steps as the iPhone's app
//  root: seed the screenshot fixture, or load the stored tokens (read
//  only), refresh them, and fetch the external application list.
//

import Foundation
import TeslaAuthKit

@MainActor
enum MacLaunch {
    /// Hosted unit tests run inside the app: they must not refresh the
    /// person's real tokens on every launch.
    static var isRunningTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    static var initialTab: AppTab {
        #if DEBUG
        ScreenshotHarness.initialTab()
        #else
        .owners
        #endif
    }

    static func start(model: AuthViewModel) async {
        #if DEBUG
        if ScreenshotScenario.isActive {
            // The fixture lives in the model only; the keychain is never read or written.
            await ScreenshotHarness.seed(model: model)
            await MacCaptureHarness.runIfRequested(model: model)
            return
        }
        #endif
        guard !isRunningTests else { return }
        await model.loadTokens()
        // A Mac that cannot read the synced items shows why and changes
        // nothing: no refresh, which would write back (#44).
        if model.storeProblem == nil {
            model.refreshAll()
        }
        await downloadLatestExternalApplicationList()
    }
}
