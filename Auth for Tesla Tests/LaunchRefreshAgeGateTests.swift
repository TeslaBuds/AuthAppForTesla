//
//  LaunchRefreshAgeGateTests.swift
//  Auth for Tesla Tests
//
//  #59: a launch posted both refresh tokens to Tesla every time, rotating
//  tokens with hours of life left. The launch refresh now goes through the
//  refresh service's age gate; only an explicit request forces a rotation.
//  The service reads an injected clock and a stub token endpoint, so
//  nothing real is called.
//

import Testing
import Foundation
import Synchronization
import TeslaAuthKit
@testable import AuthAppForTesla

/// Every refresh token posted to the stub endpoint.
final class PostedRefreshTokens: Sendable {
    private let tokens = Mutex<[String]>([])
    func append(_ token: String) { tokens.withLock { $0.append(token) } }
    var all: [String] { tokens.withLock { $0 } }
}

/// Records the force flag of every refresh, after an optional delay.
actor ForceRecordingRefresher: ActiveTokenRefreshing {
    private(set) var forceFlags: [Bool] = []
    let delay: Duration

    init(delay: Duration = .zero) { self.delay = delay }

    func refreshActive(environment: LoginEnvironment, forceRefresh: Bool) async -> TokenRefreshOutcome {
        forceFlags.append(forceRefresh)
        if delay > .zero { try? await Task.sleep(for: delay) }
        return .noToken
    }

    func activeToken(environment: LoginEnvironment) async -> Token? { nil }
}

@MainActor
@Suite("Launch refresh respects the age gate (#59)")
struct LaunchRefreshAgeGateTests {
    /// The fixed "now" of every test.
    nonisolated static let clock = Date(timeIntervalSince1970: 1_800_000_000)

    /// A controller whose stored tokens expire `expiresIn` after `clock`,
    /// and a log of what was posted to the stub endpoint.
    static func fixture(expiresIn: TimeInterval) throws -> (ControllerFixture, PostedRefreshTokens) {
        let posted = PostedRefreshTokens()
        let answer: @Sendable (String) -> TokenEndpointResponse = { refresh in
            posted.append(refresh)
            return .token(ControllerFixture.token("\(refresh)-new", expiresAt: clock.addingTimeInterval(28800)))
        }
        let fixture = try ControllerFixture(expiresAt: clock.addingTimeInterval(expiresIn),
                                            now: { clock }, answer: answer)
        return (fixture, posted)
    }

    static func model(_ fixture: ControllerFixture) -> AuthViewModel {
        AuthViewModel(summaryPublisher: fixture.summary.publisher, controller: fixture.controller)
    }

    @Test("Launch with hours of token life left posts nothing and toasts nothing")
    func launchKeepsCurrentTokens() async throws {
        let (fixture, posted) = try Self.fixture(expiresIn: 4 * 3600)
        defer { fixture.summary.tearDown() }
        let model = Self.model(fixture)
        await model.loadTokens()

        await model.refreshAll(.launch).value

        #expect(posted.all.isEmpty, "a current token must not be rotated at launch")
        #expect(model.tokenV3?.refresh_token == "RT3")
        #expect(model.tokenV4?.refresh_token == "RT4")
        #expect(model.toast == nil)
    }

    @Test("Launch refreshes a token that is due")
    func launchRefreshesDueTokens() async throws {
        let (fixture, posted) = try Self.fixture(expiresIn: 30)
        defer { fixture.summary.tearDown() }
        let model = Self.model(fixture)
        await model.loadTokens()

        await model.refreshAll(.launch).value

        #expect(posted.all.sorted() == ["RT3", "RT4"])
        #expect(model.tokenV3?.refresh_token == "RT3-new")
        #expect(model.tokenV4?.refresh_token == "RT4-new")
        #expect(model.toast?.style == .success)
    }

    @Test("The person's Refresh still rotates current tokens")
    func userRequestForcesRefresh() async throws {
        let (fixture, posted) = try Self.fixture(expiresIn: 4 * 3600)
        defer { fixture.summary.tearDown() }
        let model = Self.model(fixture)
        await model.loadTokens()

        await model.refreshAll(.userRequest).value

        #expect(posted.all.sorted() == ["RT3", "RT4"])
        #expect(model.toast?.style == .success)
    }

    @Test("Only an explicit request forces a refresh", arguments: RefreshTrigger.allCases)
    func triggerForcing(trigger: RefreshTrigger) {
        switch trigger {
        case .launch: #expect(!trigger.forcesRefresh)
        case .userRequest: #expect(trigger.forcesRefresh)
        }
    }

    @Test("Refresh pressed during the launch refresh runs after it, forced")
    func userRequestAfterLaunchStillForces() async {
        let refresher = ForceRecordingRefresher(delay: .milliseconds(100))
        let model = AuthViewModel(refresher: refresher, summaryPublisher: TokenSummaryPublisher(defaults: nil) {})

        let launch = model.refreshAll(.launch)
        let request = model.refreshAll(.userRequest)
        let joined = model.refreshAll(.userRequest)
        await launch.value
        await request.value
        await joined.value

        #expect(await refresher.forceFlags == [false, false, true, true], "launch unforced, then one forced run")
    }
}
