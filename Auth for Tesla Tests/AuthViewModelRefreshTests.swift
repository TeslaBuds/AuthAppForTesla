//
//  AuthViewModelRefreshTests.swift
//  Auth for Tesla Tests
//
//  #49/#50: a refresh that fails keeps the token on screen (so the tab
//  never flips to the sign-in screen), says why, and overlapping
//  "refresh everything" calls join one run.
//

import Testing
import Foundation
import TeslaAuthKit
@testable import AuthAppForTesla

/// Answers refreshes with scripted outcomes, counting the calls.
actor StubRefresher: ActiveTokenRefreshing {
    var outcomes: [LoginEnvironment: TokenRefreshOutcome]
    var stored: [LoginEnvironment: Token]
    private(set) var refreshCalls = 0
    var delay: Duration = .zero

    init(outcomes: [LoginEnvironment: TokenRefreshOutcome], stored: [LoginEnvironment: Token] = [:], delay: Duration = .zero) {
        self.outcomes = outcomes
        self.stored = stored
        self.delay = delay
    }

    func refreshActive(environment: LoginEnvironment, forceRefresh: Bool) async -> TokenRefreshOutcome {
        refreshCalls += 1
        if delay > .zero { try? await Task.sleep(for: delay) }
        return outcomes[environment] ?? .noToken
    }

    func activeToken(environment: LoginEnvironment) async -> Token? {
        stored[environment]
    }
}

@MainActor
@Suite("AuthViewModel refresh (#49, #50)")
struct AuthViewModelRefreshTests {
    static func token(_ refresh: String) -> Token {
        Token(access_token: "a-\(refresh)", token_type: "bearer", expires_in: 28800, refresh_token: refresh,
              expires_at: .now.addingTimeInterval(-60), region: .global)
    }

    @Test("Offline keeps both tokens on screen and says Tesla could not be reached")
    func offlineKeepsTokens() async {
        let refresher = StubRefresher(
            outcomes: [.owner: .offline(Self.token("RT3"), reason: "offline"),
                       .fleet: .offline(Self.token("RT4"), reason: "offline")],
            stored: [.owner: Self.token("RT3"), .fleet: Self.token("RT4")])
        let model = AuthViewModel(refresher: refresher)
        await model.loadTokens()

        await model.refreshAll().value

        #expect(model.tokenV3?.refresh_token == "RT3")
        #expect(model.tokenV4?.refresh_token == "RT4")
        #expect(model.refreshProblem(for: .owner)?.kind == .offline)
        #expect(model.toast?.style == .error)
        #expect(model.toast?.message.contains("Couldn't reach Tesla") == true)
    }

    @Test("A refused refresh token keeps the account, flagged for sign-in")
    func refusedKeepsAccount() async {
        let refresher = StubRefresher(
            outcomes: [.owner: .refreshed(Self.token("RT3-new")),
                       .fleet: .needsSignIn(Self.token("RT4"), reason: "login_required")],
            stored: [.owner: Self.token("RT3"), .fleet: Self.token("RT4")])
        let model = AuthViewModel(refresher: refresher)
        await model.loadTokens()

        await model.refreshAll().value

        #expect(model.tokenV3?.refresh_token == "RT3-new")
        #expect(model.tokenV4?.refresh_token == "RT4")
        #expect(model.refreshProblem(for: .owner) == nil)
        #expect(model.refreshProblem(for: .fleet)?.kind == .needsSignIn)
        #expect(model.toast?.message.contains("login_required") == true)
    }

    @Test("The problem no longer applies once a newer token is shown")
    func problemClearsWithNewToken() async {
        let refresher = StubRefresher(
            outcomes: [.fleet: .needsSignIn(Self.token("RT4"), reason: "login_required")],
            stored: [.fleet: Self.token("RT4")])
        let model = AuthViewModel(refresher: refresher)
        await model.loadTokens()
        await model.refreshAll().value
        #expect(model.refreshProblem(for: .fleet) != nil)

        model.tokenV4 = Self.token("RT4-after-sign-in")
        #expect(model.refreshProblem(for: .fleet) == nil)
    }

    @Test("No stored token never clears what is shown, and toasts nothing")
    func noTokenChangesNothing() async {
        let refresher = StubRefresher(outcomes: [:])
        let model = AuthViewModel(refresher: refresher)
        model.tokenV3 = Self.token("shown")
        await model.refreshAll().value
        #expect(model.tokenV3?.refresh_token == "shown")
        #expect(model.toast == nil)
    }

    @Test("Overlapping refresh-all calls join one run")
    func refreshAllIsSingleFlight() async {
        let refresher = StubRefresher(
            outcomes: [.owner: .refreshed(Self.token("RT3-new")), .fleet: .refreshed(Self.token("RT4-new"))],
            delay: .milliseconds(100))
        let model = AuthViewModel(refresher: refresher)

        let first = model.refreshAll()
        let second = model.refreshAll()
        await first.value
        await second.value

        #expect(await refresher.refreshCalls == 2, "one refresh per API, not two runs")
        #expect(model.toast?.style == .success)
    }
}
