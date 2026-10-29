//
//  LaunchRefreshTriggerTests.swift
//  AuthAppForTeslaMacTests
//
//  #59 on the Mac: the launch refresh-all (MacLaunch) goes through the
//  refresh service's age gate; the menu-bar menu and ⌘R still force a
//  rotation. A recording refresher stands in for Tesla.
//

import Foundation
import Testing
import TeslaAuthKit
@testable import AuthAppForTeslaMac

/// Records the force flag of every refresh. Never calls Tesla.
actor MacForceRecordingRefresher: ActiveTokenRefreshing {
    private(set) var forceFlags: [Bool] = []

    func refreshActive(environment: LoginEnvironment, forceRefresh: Bool) async -> TokenRefreshOutcome {
        forceFlags.append(forceRefresh)
        return .noToken
    }

    func activeToken(environment: LoginEnvironment) async -> Token? { nil }
}

@MainActor
@Suite("Mac launch refresh respects the age gate (#59)")
struct LaunchRefreshTriggerTests {
    @Test("Launch asks for no forced refresh; a request forces both")
    func launchIsNotForced() async {
        let refresher = MacForceRecordingRefresher()
        let model = AuthViewModel(refresher: refresher, summaryPublisher: TokenSummaryPublisher(defaults: nil) {})

        await model.refreshAll(.launch).value
        #expect(await refresher.forceFlags == [false, false])

        await model.refreshAll(.userRequest).value
        #expect(await refresher.forceFlags == [false, false, true, true])
    }
}
