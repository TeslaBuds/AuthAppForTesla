//
//  TokenRefreshServiceTests.swift
//  TeslaAuthKitTests
//
//  Refresh never destroys a stored profile (#49, #50): single flight,
//  rotation races, refusals and offline all keep the account.
//

import Testing
import Foundation
@testable import TeslaAuthKit

/// A token endpoint whose answers the test scripts, counting posts.
final class ScriptedTransport: TokenRefreshTransport, @unchecked Sendable {
    private let lock = NSLock()
    private var _posted: [String] = []
    /// Called with the posted refresh token; returns Tesla's answer.
    let answer: @Sendable (String) async -> TokenEndpointResponse

    init(answer: @escaping @Sendable (String) async -> TokenEndpointResponse) {
        self.answer = answer
    }

    var posted: [String] { lock.withLock { _posted } }

    func refresh(refreshToken: String, region: TokenRegion, environment: LoginEnvironment) async -> TokenEndpointResponse {
        lock.withLock { _posted.append(refreshToken) }
        return await answer(refreshToken)
    }
}

@Suite("Token refresh service")
struct TokenRefreshServiceTests {
    static func token(_ refresh: String, expiresIn: TimeInterval = -60) -> Token {
        Token(access_token: "a-\(refresh)", token_type: "bearer", expires_in: 28800,
              refresh_token: refresh, expires_at: Date.now.addingTimeInterval(expiresIn), region: .global)
    }

    /// A store holding one Fleet profile with refresh token `refresh`.
    static func seeded(_ refresh: String = "RT1") throws -> (RecordingStorage, TokenProfileStore, UUID) {
        let profile = TokenProfile(name: "Fleet", token: token(refresh))
        let collection = TokenProfileCollection(profiles: [profile], activeProfileId: profile.id)
        let storage = RecordingStorage([kTokenV4Profiles: try JSONEncoder().encode(collection)])
        return (storage, TokenProfileStore(storage: storage), profile.id)
    }

    static func stored(_ storage: RecordingStorage) throws -> TokenProfileCollection {
        try JSONDecoder().decode(TokenProfileCollection.self, from: try #require(storage.value(kTokenV4Profiles)))
    }

    static func service(_ store: TokenProfileStore, _ transport: ScriptedTransport, ledger: InMemoryRejectionLedger = .init()) -> TokenRefreshService {
        TokenRefreshService(store: store, transport: transport, ledger: ledger, maxAttempts: 3, retryDelay: .zero)
    }

    @Test("login_required keeps the profile, flags it, and writes nothing")
    func refusalKeepsProfile() async throws {
        let (storage, store, id) = try Self.seeded()
        let transport = ScriptedTransport { _ in .rejected(reason: "login_required") }
        let ledger = InMemoryRejectionLedger()
        let service = Self.service(store, transport, ledger: ledger)

        let outcome = await service.refresh(environment: .fleet, forceRefresh: true)
        guard case .needsSignIn(let kept, let reason) = outcome else { Issue.record("expected needsSignIn, got \(outcome)"); return }
        #expect(kept.refresh_token == "RT1")
        #expect(reason == "login_required")
        #expect(try Self.stored(storage).profiles.map(\.id) == [id])
        #expect(storage.writes.isEmpty, "a refusal wrote: \(storage.writes)")
        #expect(ledger.rejection(for: "RT1") == "login_required")
        #expect(transport.posted == ["RT1"], "a refusal is not retried")
    }

    @Test("A flagged token is not posted again unless forced")
    func flaggedTokenNotPosted() async throws {
        let (_, store, _) = try Self.seeded()
        let ledger = InMemoryRejectionLedger()
        ledger.recordRejection(of: "RT1", reason: "login_required")
        let transport = ScriptedTransport { _ in .rejected(reason: "login_required") }
        let outcome = await Self.service(store, transport, ledger: ledger).refresh(environment: .fleet, forceRefresh: false)
        guard case .needsSignIn = outcome else { Issue.record("expected needsSignIn"); return }
        #expect(transport.posted.isEmpty)
    }

    @Test("Two overlapping refreshes post the refresh token once")
    func singleFlight() async throws {
        let (storage, store, _) = try Self.seeded()
        let transport = ScriptedTransport { posted in
            try? await Task.sleep(for: .milliseconds(200))
            return posted == "RT1" ? .token(Self.token("RT2", expiresIn: 28800)) : .rejected(reason: "login_required")
        }
        let service = Self.service(store, transport)

        async let first = service.refresh(environment: .fleet, forceRefresh: true)
        async let second = service.refresh(environment: .fleet, forceRefresh: true)
        let (a, b) = await (first, second)

        #expect(transport.posted == ["RT1"])
        #expect(a.freshToken?.refresh_token == "RT2")
        #expect(b.freshToken?.refresh_token == "RT2")
        #expect(try Self.stored(storage).profiles.first?.token.refresh_token == "RT2")
    }

    @Test("Another device rotated first: its newer token is the answer, not sign-in")
    func rotationRaceRefusal() async throws {
        let (storage, store, id) = try Self.seeded()
        let ledger = InMemoryRejectionLedger()
        let transport = ScriptedTransport { _ in
            // The iPhone's RT2 syncs in while this device posts RT1.
            var collection = try! Self.stored(storage)
            collection.profiles[0].token = Self.token("RT2", expiresIn: 28800)
            storage.put(kTokenV4Profiles, try! JSONEncoder().encode(collection))
            return .rejected(reason: "login_required")
        }
        let outcome = await Self.service(store, transport, ledger: ledger).refresh(environment: .fleet, forceRefresh: true)
        #expect(outcome.freshToken?.refresh_token == "RT2")
        #expect(ledger.rejection(for: "RT1") == nil)
        #expect(try Self.stored(storage).profiles.map(\.id) == [id])
        #expect(try Self.stored(storage).profiles.first?.token.refresh_token == "RT2")
    }

    @Test("A refresh based on a stale token never overwrites a newer rotation")
    func staleRefreshDoesNotOverwrite() async throws {
        let (storage, store, _) = try Self.seeded()
        let transport = ScriptedTransport { _ in
            var collection = try! Self.stored(storage)
            collection.profiles[0].token = Self.token("RT-other-device", expiresIn: 28800)
            storage.put(kTokenV4Profiles, try! JSONEncoder().encode(collection))
            return .token(Self.token("RT-mine", expiresIn: 28800))
        }
        let outcome = await Self.service(store, transport).refresh(environment: .fleet, forceRefresh: true)
        #expect(try Self.stored(storage).profiles.first?.token.refresh_token == "RT-other-device")
        #expect(outcome.freshToken?.refresh_token == "RT-other-device")
    }

    @Test("Offline keeps the stored token and changes nothing, after retrying")
    func offlineKeepsToken() async throws {
        let (storage, store, _) = try Self.seeded()
        let transport = ScriptedTransport { _ in .unavailable(reason: "The Internet connection appears to be offline.") }
        let ledger = InMemoryRejectionLedger()
        let outcome = await Self.service(store, transport, ledger: ledger).refresh(environment: .fleet, forceRefresh: true)
        guard case .offline(let kept, _) = outcome else { Issue.record("expected offline, got \(outcome)"); return }
        #expect(kept.refresh_token == "RT1")
        #expect(outcome.token?.refresh_token == "RT1")
        #expect(outcome.freshToken == nil)
        #expect(transport.posted.count == 3)
        #expect(storage.writes.isEmpty)
        #expect(ledger.rejection(for: "RT1") == nil)
    }

    @Test("A token that is not due is returned without posting")
    func notDue() async throws {
        let profile = TokenProfile(name: "Fleet", token: Self.token("RT1", expiresIn: 3600))
        let collection = TokenProfileCollection(profiles: [profile], activeProfileId: profile.id)
        let storage = RecordingStorage([kTokenV4Profiles: try JSONEncoder().encode(collection)])
        let transport = ScriptedTransport { _ in .rejected(reason: "x") }
        let outcome = await Self.service(TokenProfileStore(storage: storage), transport).refresh(environment: .fleet, forceRefresh: false)
        guard case .current = outcome else { Issue.record("expected current"); return }
        #expect(transport.posted.isEmpty)
    }

    @Test("A successful refresh clears an earlier refusal and stores the new token")
    func successStores() async throws {
        let (storage, store, _) = try Self.seeded()
        let ledger = InMemoryRejectionLedger()
        ledger.recordRejection(of: "RT1", reason: "transient")
        let transport = ScriptedTransport { _ in .token(Self.token("RT2", expiresIn: 28800)) }
        let outcome = await Self.service(store, transport, ledger: ledger).refresh(environment: .fleet, forceRefresh: true)
        guard case .refreshed(let token) = outcome else { Issue.record("expected refreshed"); return }
        #expect(token.refresh_token == "RT2")
        #expect(ledger.rejection(for: "RT1") == nil)
        #expect(try Self.stored(storage).profiles.first?.token.refresh_token == "RT2")
        // The legacy mirror follows the active profile.
        let mirror = try JSONDecoder().decode(Token.self, from: try #require(storage.value(kTokenV4)))
        #expect(mirror.refresh_token == "RT2")
    }

    @Test("No stored profile is noToken")
    func noProfile() async {
        let transport = ScriptedTransport { _ in .rejected(reason: "x") }
        let outcome = await Self.service(TokenProfileStore(storage: RecordingStorage()), transport).refresh(environment: .owner, forceRefresh: true)
        guard case .noToken = outcome else { Issue.record("expected noToken"); return }
        #expect(transport.posted.isEmpty)
    }
}

@Suite("Rejection ledger")
struct RejectionLedgerTests {
    @Test("UserDefaults ledger stores fingerprints, never the token")
    func storesFingerprintOnly() throws {
        let suite = "TeslaAuthKitTests.ledger.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let ledger = UserDefaultsRejectionLedger(defaults: defaults, key: "k")
        ledger.recordRejection(of: "secret-refresh-token", reason: "login_required")
        #expect(ledger.rejection(for: "secret-refresh-token") == "login_required")
        #expect(ledger.rejection(for: "another") == nil)
        let raw = try #require(defaults.dictionary(forKey: "k"))
        #expect(!raw.keys.contains { $0.contains("secret") })
        ledger.clearRejection(of: "secret-refresh-token")
        #expect(ledger.rejection(for: "secret-refresh-token") == nil)
    }
}
