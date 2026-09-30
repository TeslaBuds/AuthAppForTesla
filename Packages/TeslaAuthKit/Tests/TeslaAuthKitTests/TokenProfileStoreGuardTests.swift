//
//  TokenProfileStoreGuardTests.swift
//  Auth for Tesla Tests
//
//  The sync-wipe guard (AuthAppForTesla#44): a device that cannot read
//  the synced profile lists never writes one. These run against an
//  in-memory storage that records every write; the real-keychain,
//  two-launch proof lives in the Mac test target.
//

import Testing
import Foundation
import Security
@testable import TeslaAuthKit

/// In-memory keychain that records every write and can refuse reads.
final class RecordingStorage: SyncedItemStorage, @unchecked Sendable {
    private let lock = NSLock()
    private var items: [String: Data] = [:]
    private(set) var writes: [String] = []
    /// When set, every read fails with this status, like a keychain the
    /// app's signature has no access to.
    var readFailure: OSStatus?
    /// Runs once after the first read, to simulate an iCloud sync
    /// landing between the store's read and its write.
    var afterFirstRead: ((RecordingStorage) -> Void)?

    init(_ items: [String: Data] = [:]) { self.items = items }

    func value(_ key: String) -> Data? { lock.withLock { items[key] } }
    func put(_ key: String, _ data: Data?) { lock.withLock { items[key] = data } }

    func read(_ key: String) -> KeychainReadResult {
        let result: KeychainReadResult = lock.withLock {
            if let readFailure { return .failed(readFailure) }
            return items[key].map(KeychainReadResult.found) ?? .notFound
        }
        if let hook = afterFirstRead {
            afterFirstRead = nil
            hook(self)
        }
        return result
    }

    func add(_ data: Data, forKey key: String) -> OSStatus {
        lock.withLock {
            writes.append("add \(key)")
            if items[key] != nil { return errSecDuplicateItem }
            items[key] = data
            return errSecSuccess
        }
    }

    func replace(_ data: Data, forKey key: String) -> OSStatus {
        lock.withLock {
            writes.append("replace \(key)")
            guard items[key] != nil else { return errSecItemNotFound }
            items[key] = data
            return errSecSuccess
        }
    }

    func remove(_ key: String) -> OSStatus {
        lock.withLock {
            writes.append("remove \(key)")
            return items.removeValue(forKey: key) == nil ? errSecItemNotFound : errSecSuccess
        }
    }
}

@Suite("TokenProfileStore sync-wipe guard")
struct TokenProfileStoreGuardTests {
    private static func token(_ name: String) -> Token {
        Token(access_token: "a-\(name)", token_type: "bearer", expires_in: 3600,
              refresh_token: "r-\(name)", expires_at: nil, region: .global)
    }

    private static func encoded(_ names: [String]) throws -> (Data, TokenProfileCollection) {
        var collection = TokenProfileCollection()
        for name in names { collection.upsert(TokenProfile(name: name, token: token(name))) }
        return (try JSONEncoder().encode(collection), collection)
    }

    private static func decode(_ data: Data?) throws -> TokenProfileCollection {
        try JSONDecoder().decode(TokenProfileCollection.self, from: try #require(data))
    }

    @Test("An unreadable keychain blocks every write, and reports why")
    func unreadableBlocksEverything() async throws {
        let (seeded, collection) = try Self.encoded(["Home", "Work", "Fleet car"])
        let storage = RecordingStorage([kTokenV3Profiles: seeded])
        storage.readFailure = errSecMissingEntitlement
        let store = TokenProfileStore(storage: storage)
        let id = try #require(collection.profiles.first?.id)

        guard case .unavailable(.unreadable(errSecMissingEntitlement)) = await store.loadState(environment: .owner) else {
            Issue.record("expected unavailable"); return
        }
        await #expect(throws: TokenStoreError.unreadable(errSecMissingEntitlement)) {
            try await store.upsert(profile: TokenProfile(name: "New", token: Self.token("n")), environment: .owner, makeActive: true)
        }
        await #expect(throws: TokenStoreError.self) { try await store.updateActiveToken(Self.token("x"), environment: .owner) }
        await #expect(throws: TokenStoreError.self) { try await store.updateProfileToken(id: id, token: Self.token("x"), environment: .owner) }
        await #expect(throws: TokenStoreError.self) { try await store.setActive(id: id, environment: .owner) }
        await #expect(throws: TokenStoreError.self) { try await store.rename(id: id, to: "x", environment: .owner) }
        await #expect(throws: TokenStoreError.self) { try await store.delete(id: id, environment: .owner) }
        await #expect(throws: TokenStoreError.self) { try await store.clearLegacyMirror(environment: .owner) }

        #expect(storage.writes.isEmpty)
        #expect(storage.value(kTokenV3Profiles) == seeded)
    }

    @Test("A list that does not decode is never overwritten")
    func undecodableIsNeverOverwritten() async throws {
        let garbage = Data("{\"from\":\"a newer version\"}".utf8)
        let storage = RecordingStorage([kTokenV4Profiles: garbage])
        let store = TokenProfileStore(storage: storage)

        await #expect(throws: TokenStoreError.undecodable) {
            try await store.updateActiveToken(Self.token("x"), environment: .fleet)
        }
        #expect(storage.writes.isEmpty)
        #expect(storage.value(kTokenV4Profiles) == garbage)
    }

    @Test("A legacy entry that cannot be read blocks the migration")
    func unreadableLegacyBlocksMigration() async throws {
        let storage = RecordingStorage()
        storage.readFailure = errSecInteractionNotAllowed
        let store = TokenProfileStore(storage: storage)
        _ = await store.load(environment: .owner)
        #expect(storage.writes.isEmpty)
    }

    @Test("A read list is updated in place, with every other profile kept")
    func readListIsUpdated() async throws {
        let (seeded, collection) = try Self.encoded(["Home", "Work", "Fleet car"])
        let storage = RecordingStorage([kTokenV3Profiles: seeded])
        let store = TokenProfileStore(storage: storage)

        let loaded = await store.load(environment: .owner)
        #expect(loaded.profiles.map(\.name) == ["Home", "Work", "Fleet car"])

        try await store.updateActiveToken(Self.token("refreshed"), environment: .owner)
        let stored = try Self.decode(storage.value(kTokenV3Profiles))
        #expect(stored.profiles.count == 3)
        #expect(stored.profiles.first?.token.access_token == "a-refreshed")
        #expect(stored.activeProfileId == collection.activeProfileId)
        #expect(!storage.writes.contains { $0.hasPrefix("add \(kTokenV3Profiles)") })
    }

    @Test("A sync landing between read and write is merged, never overwritten")
    func concurrentSyncIsMerged() async throws {
        let (seeded, _) = try Self.encoded(["Home"])
        let (synced, _) = try Self.encoded(["Home", "From the iPhone"])
        let storage = RecordingStorage([kTokenV3Profiles: seeded])
        storage.afterFirstRead = { $0.put(kTokenV3Profiles, synced) }
        let store = TokenProfileStore(storage: storage)

        // The sync lands after the store read the one-profile list; the
        // compare-and-swap notices and re-applies the change to the
        // synced list instead of writing over it.
        try await store.upsert(profile: TokenProfile(name: "Mac", token: Self.token("mac")), environment: .owner, makeActive: false)
        let stored = try Self.decode(storage.value(kTokenV3Profiles))
        #expect(Set(stored.profiles.map(\.name)) == ["Home", "From the iPhone", "Mac"])
    }

    @Test("A missing list is only ever created, never overwritten")
    func missingListIsAddedOnly() async throws {
        let storage = RecordingStorage()
        let store = TokenProfileStore(storage: storage)
        try await store.upsert(profile: TokenProfile(name: "Mac", token: Self.token("mac")), environment: .fleet, makeActive: true)
        #expect(storage.writes.first == "add \(kTokenV4Profiles)")
        #expect(try Self.decode(storage.value(kTokenV4Profiles)).profiles.map(\.name) == ["Mac"])
    }

    @Test("Nothing is written where nothing exists and nothing changes")
    func emptyIsNeverCreated() async throws {
        let storage = RecordingStorage()
        let store = TokenProfileStore(storage: storage)
        _ = try await store.delete(id: UUID(), environment: .owner)
        _ = try await store.setActive(id: UUID(), environment: .owner)
        #expect(storage.writes.isEmpty)
    }

    @Test("Only deleting the last profile of a read list may leave it empty")
    func emptyOnlyByExplicitDelete() async throws {
        let (seeded, collection) = try Self.encoded(["Only"])
        let storage = RecordingStorage([kTokenV3Profiles: seeded])
        let store = TokenProfileStore(storage: storage)
        let id = try #require(collection.profiles.first?.id)
        try await store.delete(id: id, environment: .owner)
        #expect(try Self.decode(storage.value(kTokenV3Profiles)).profiles.isEmpty)
    }

    @Test("The legacy token is migrated once, with an add")
    func legacyMigration() async throws {
        let legacy = try JSONEncoder().encode(Self.token("legacy"))
        let storage = RecordingStorage([kTokenV3: legacy])
        let store = TokenProfileStore(storage: storage)
        let loaded = await store.load(environment: .owner)
        #expect(loaded.profiles.map(\.name) == ["Owners Account"])
        #expect(storage.writes.first == "add \(kTokenV3Profiles)")
        #expect(try Self.decode(storage.value(kTokenV3Profiles)).profiles.count == 1)
    }
}
