//
//  TokenSummaryWriterTests.swift
//  Auth for Tesla Tests
//
//  #52: a refresh made outside the view model — a Shortcut — updates the
//  widget summary, through #58's idempotent publisher, coalesced.
//

import Testing
import Foundation
import TeslaAuthKit
@testable import AuthAppForTesla

@Suite("Widget summary follows the store (#52)")
struct TokenSummaryWriterTests {
    @Test("A Shortcut's refresh of a chosen Fleet account updates the widget summary")
    func shortcutRefreshUpdatesSummary() async throws {
        let fixture = try ControllerFixture()
        defer { fixture.summary.tearDown() }

        let token = await fixture.controller.acquireTokenV4Silent(profileId: fixture.fleetId, forceRefresh: true)

        let refreshed = try #require(token)
        #expect(refreshed.refresh_token == "RT4-new")
        let defaults = fixture.summary.defaults
        #expect(defaults.bool(forKey: TokenSummaryPublisher.Key.fleetHasToken))
        #expect(defaults.object(forKey: TokenSummaryPublisher.Key.fleetExpiresAt) as? Date == refreshed.expires_at)
        #expect(defaults.object(forKey: TokenSummaryPublisher.Key.ownersExpiresAt) as? Date == ControllerFixture.staleExpiry)
        #expect(fixture.summary.reloads.value == 1)
    }

    @Test("The intents' active-account refresh updates the summary too")
    func activeRefreshUpdatesSummary() async throws {
        let fixture = try ControllerFixture()
        defer { fixture.summary.tearDown() }

        let token = try #require(await fixture.controller.acquireTokenV3Silent(forceRefresh: true))

        #expect(fixture.summary.defaults.object(forKey: TokenSummaryPublisher.Key.ownersExpiresAt) as? Date == token.expires_at)
    }

    @Test("A refused refresh changes nothing and reloads no widget")
    func refusedRefreshWritesNothing() async throws {
        let fixture = try ControllerFixture { _ in .rejected(reason: "login_required") }
        defer { fixture.summary.tearDown() }

        #expect(await fixture.controller.acquireTokenV4Silent(profileId: fixture.fleetId, forceRefresh: true) == nil)
        #expect(fixture.summary.reloads.value == 0)
    }

    @Test("Overlapping requests coalesce, and the last change is always published")
    func requestsCoalesce() async throws {
        let fixture = SummaryFixture()
        defer { fixture.tearDown() }
        let writer = TokenSummaryWriter(publisher: fixture.publisher)
        let expiry = Date(timeIntervalSince1970: 2_000_000_000)
        let summary = TokenSummary(hasOwnersToken: true, ownersExpiresAt: expiry, hasFleetToken: false, fleetExpiresAt: nil)

        let tasks = await (0..<5).asyncMap { _ in await writer.update { summary } }
        for task in tasks { await task.value }

        #expect(await writer.passes < 5)
        #expect(await writer.stored == summary)
        #expect(fixture.reloads.value == 1)
    }

    @Test("A Shortcut's refresh tells the app's model to reload (#52)")
    @MainActor
    func modelReloadsAfterStoreChange() async throws {
        let fixture = try ControllerFixture()
        defer { fixture.summary.tearDown() }
        let model = AuthViewModel(summaryPublisher: fixture.summary.publisher,
                                  announcer: AccessibilityAnnouncer { _ in },
                                  controller: fixture.controller)
        await model.loadTokens()
        model.startObservingStore()
        #expect(model.tokenV4?.refresh_token == "RT4")

        _ = await fixture.controller.acquireTokenV4Silent(profileId: fixture.fleetId, forceRefresh: true)

        for _ in 0..<100 where model.tokenV4?.refresh_token != "RT4-new" {
            try await Task.sleep(for: .milliseconds(20))
        }
        #expect(model.tokenV4?.refresh_token == "RT4-new")
        #expect(model.profilesV4.activeProfile?.token.refresh_token == "RT4-new")
    }
}

extension Sequence {
    func asyncMap<T>(_ transform: (Element) async -> T) async -> [T] {
        var results: [T] = []
        for element in self { results.append(await transform(element)) }
        return results
    }
}
