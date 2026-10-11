//
//  TokenSummaryPublisherTests.swift
//  Auth for Tesla Tests
//
//  #58: the widget summary is written and the widget reloaded only when the
//  summary changed, and assigning both tokens costs one reload, not two.
//

import Testing
import Foundation
import Synchronization
import TeslaAuthKit
@testable import AuthAppForTesla

/// Counts widget reloads.
final class ReloadCounter: Sendable {
    private let count = Mutex(0)
    var value: Int { count.withLock { $0 } }
    func increment() { count.withLock { $0 += 1 } }
}

/// A publisher writing to a throwaway suite, counting reloads.
struct SummaryFixture {
    let suiteName = "test.tokenSummary.\(UUID().uuidString)"
    let reloads = ReloadCounter()
    var defaults: UserDefaults { UserDefaults(suiteName: suiteName)! }

    var publisher: TokenSummaryPublisher {
        let reloads = reloads
        return TokenSummaryPublisher(defaults: defaults) { reloads.increment() }
    }

    func tearDown() { defaults.removePersistentDomain(forName: suiteName) }
}

@MainActor
@Suite("Widget token summary (#58)")
struct TokenSummaryPublisherTests {
    static let expiry3 = Date(timeIntervalSince1970: 2_000_000_000)
    static let expiry4 = Date(timeIntervalSince1970: 2_000_003_600)
    static let owners = Token(access_token: "a3", token_type: "bearer", expires_in: 28800, refresh_token: "RT3",
                              expires_at: expiry3, region: .global)
    static let fleet = Token(access_token: "a4", token_type: "bearer", expires_in: 28800, refresh_token: "RT4",
                             expires_at: expiry4, region: .global)

    @Test("Publishing the stored summary again writes nothing and reloads nothing")
    func publishIsIdempotent() {
        let fixture = SummaryFixture()
        defer { fixture.tearDown() }
        let summary = TokenSummary(owners: Self.owners, fleet: Self.fleet)

        #expect(fixture.publisher.publish(summary))
        #expect(!fixture.publisher.publish(summary))
        #expect(!fixture.publisher.publish(TokenSummary(owners: Self.owners, fleet: Self.fleet)))
        #expect(fixture.reloads.value == 1)
        #expect(fixture.publisher.stored == summary)
    }

    @Test("A changed expiry or a sign-out is published")
    func changesArePublished() {
        let fixture = SummaryFixture()
        defer { fixture.tearDown() }
        fixture.publisher.publish(TokenSummary(owners: Self.owners, fleet: Self.fleet))

        var later = Self.fleet
        later.expires_at = Self.expiry4.addingTimeInterval(28800)
        #expect(fixture.publisher.publish(TokenSummary(owners: Self.owners, fleet: later)))
        #expect(fixture.publisher.publish(TokenSummary(owners: nil, fleet: later)))
        #expect(fixture.reloads.value == 3)
        #expect(fixture.defaults.bool(forKey: TokenSummaryPublisher.Key.ownersHasToken) == false)
        #expect(fixture.defaults.object(forKey: TokenSummaryPublisher.Key.fleetExpiresAt) as? Date == later.expires_at)
    }

    @Test("A summary another process stored (a Shortcut, #52) is not reloaded again")
    func respectsSummaryWrittenElsewhere() {
        let fixture = SummaryFixture()
        defer { fixture.tearDown() }
        let summary = TokenSummary(owners: Self.owners, fleet: Self.fleet)
        TokenSummaryPublisher(defaults: fixture.defaults) {}.publish(summary)

        #expect(!fixture.publisher.publish(summary))
        #expect(fixture.reloads.value == 0)
    }

    /// Launch: load both tokens, then the launch refresh-all. Returns the
    /// token assignments (one reload each before #58) and the reloads now.
    func launch(fixture: SummaryFixture, outcomes: [LoginEnvironment: TokenRefreshOutcome]) async -> (assignments: Int, reloads: Int) {
        let refresher = StubRefresher(outcomes: outcomes, stored: [.owner: Self.owners, .fleet: Self.fleet])
        let model = AuthViewModel(refresher: refresher, summaryPublisher: fixture.publisher)
        await model.loadTokens()
        await model.pendingTokenSummary?.value
        await model.refreshAll().value
        await model.pendingTokenSummary?.value
        return (model.tokenSummaryRequests, fixture.reloads.value)
    }

    @Test("First launch, tokens still current: 4 assignments, 1 widget reload")
    func firstLaunchReloadsOnce() async {
        let fixture = SummaryFixture()
        defer { fixture.tearDown() }
        let counts = await launch(fixture: fixture, outcomes: [.owner: .current(Self.owners), .fleet: .current(Self.fleet)])
        #expect(counts.assignments == 4, "before #58 this was 4 reloads")
        #expect(counts.reloads == 1)
        #expect(fixture.publisher.stored == TokenSummary(owners: Self.owners, fleet: Self.fleet))
    }

    @Test("Later launch, summary unchanged (offline): 0 widget reloads")
    func unchangedLaunchReloadsNothing() async {
        let fixture = SummaryFixture()
        defer { fixture.tearDown() }
        fixture.publisher.publish(TokenSummary(owners: Self.owners, fleet: Self.fleet))
        let before = fixture.reloads.value

        let counts = await launch(fixture: fixture, outcomes: [.owner: .offline(Self.owners, reason: "offline"),
                                                              .fleet: .offline(Self.fleet, reason: "offline")])
        #expect(counts.assignments == 4)
        #expect(counts.reloads - before == 0)
    }

    @Test("Launch whose refresh rotates both tokens: 1 reload for the new expiries")
    func rotatedLaunchReloadsOncePerChange() async {
        let fixture = SummaryFixture()
        defer { fixture.tearDown() }
        fixture.publisher.publish(TokenSummary(owners: Self.owners, fleet: Self.fleet))
        let before = fixture.reloads.value
        var owners = Self.owners, fleet = Self.fleet
        owners.expires_at = Self.expiry3.addingTimeInterval(28800)
        fleet.expires_at = Self.expiry4.addingTimeInterval(28800)

        let counts = await launch(fixture: fixture, outcomes: [.owner: .refreshed(owners), .fleet: .refreshed(fleet)])
        #expect(counts.reloads - before == 1, "both new expiries in one reload")
        #expect(fixture.publisher.stored == TokenSummary(owners: owners, fleet: fleet))
    }

    @Test("Assigning both tokens together (a profile action) is one reload, not two")
    func pairIsCoalesced() async {
        let fixture = SummaryFixture()
        defer { fixture.tearDown() }
        let model = AuthViewModel(refresher: StubRefresher(outcomes: [:]), summaryPublisher: fixture.publisher)

        model.tokenV3 = Self.owners
        model.tokenV4 = Self.fleet
        await model.pendingTokenSummary?.value

        #expect(model.tokenSummaryRequests == 2)
        #expect(fixture.reloads.value == 1)
        #expect(fixture.publisher.stored == TokenSummary(owners: Self.owners, fleet: Self.fleet))
    }
}
