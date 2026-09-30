//
//  KeychainGuardProofTests.swift
//  AuthAppForTeslaMacTests
//
//  The real-keychain, multi-launch proof of the sync-wipe guard
//  (AuthAppForTesla#44). Not an in-memory fake: these run inside the
//  signed Mac app, against the data-protection keychain, in the
//  `group.global` access group every synced token lives in.
//
//  Each phase is its own `xcodebuild test` launch, selected with
//  TEST_RUNNER_AFT_PROOF_PHASE (scripts/keychain-guard-proof.sh drives them):
//
//    seed     entitled   seed a fixture: 3 Owners + 2 Fleet profiles and
//                        the legacy mirrors; launch 1 reads them all and
//                        a refresh-style write lands
//    reread   entitled   launch 2, a new process: every profile and the
//                        refreshed token are there; prints a fingerprint
//    noaccess NO group   the same app signed WITHOUT group.global: the
//                        store reports unreadable, every change is
//                        refused, and not one write reaches the keychain
//    verify   entitled   the fixture is byte-identical to launch 2's
//                        fingerprint: the no-access launch changed nothing
//    cleanup  entitled   remove the fixture
//
//  The fixture uses its own service name, so the person's real Auth for
//  Tesla items are never written. The only look at those is a read-only
//  census of their keys (no data) in the seed phase.
//

import Foundation
import Security
import CryptoKit
import Testing
import TeslaAuthKit
@testable import AuthAppForTeslaMac

/// Counts every write the store attempts, then passes it to the real keychain.
final class CountingKeychainStorage: SyncedItemStorage, @unchecked Sendable {
    let base: KeychainSyncedItemStorage
    private let lock = NSLock()
    private(set) var writeAttempts: [String] = []

    init(_ base: KeychainSyncedItemStorage) { self.base = base }

    func read(_ key: String) -> KeychainReadResult { base.read(key) }
    func add(_ data: Data, forKey key: String) -> OSStatus {
        lock.withLock { writeAttempts.append("add \(key)") }
        return base.add(data, forKey: key)
    }
    func replace(_ data: Data, forKey key: String) -> OSStatus {
        lock.withLock { writeAttempts.append("replace \(key)") }
        return base.replace(data, forKey: key)
    }
    func remove(_ key: String) -> OSStatus {
        lock.withLock { writeAttempts.append("remove \(key)") }
        return base.remove(key)
    }
}

enum GuardProofFixture {
    /// The proof's own service: same access group and sync as production.
    static let keychain = KeychainWrapper(serviceName: "AuthForTesla.GuardProof", accessGroup: "group.global", iCloudSync: true)
    static var storage: KeychainSyncedItemStorage { KeychainSyncedItemStorage(keychain: keychain) }

    static let phase = ProcessInfo.processInfo.environment["AFT_PROOF_PHASE"] ?? ""
    static let expectedFingerprint = ProcessInfo.processInfo.environment["AFT_PROOF_FINGERPRINT"] ?? ""

    static let ownerNames = ["Personal", "Work", "Family car"]
    static let fleetNames = ["Production", "Staging"]
    static let ownerIDs = [
        UUID(uuidString: "0A0A0A0A-0000-4000-8000-000000000001")!,
        UUID(uuidString: "0A0A0A0A-0000-4000-8000-000000000002")!,
        UUID(uuidString: "0A0A0A0A-0000-4000-8000-000000000003")!,
    ]
    static let fleetIDs = [
        UUID(uuidString: "0B0B0B0B-0000-4000-8000-000000000001")!,
        UUID(uuidString: "0B0B0B0B-0000-4000-8000-000000000002")!,
    ]
    static let allKeys = [kTokenV3Profiles, kTokenV4Profiles, kTokenV3, kTokenV4]

    static func token(_ name: String) -> Token {
        Token(access_token: "proof-access-\(name)", token_type: "bearer", expires_in: 28800,
              refresh_token: "proof-refresh-\(name)", expires_at: nil, region: .global)
    }

    static func collection(_ names: [String], ids: [UUID]) -> TokenProfileCollection {
        var collection = TokenProfileCollection()
        for (name, id) in zip(names, ids) { collection.upsert(TokenProfile(id: id, name: name, token: token(name))) }
        return collection
    }

    /// SHA-256 over every fixture item's raw bytes, in key order.
    static func fingerprint() -> String {
        var hasher = SHA256()
        for key in allKeys {
            hasher.update(data: Data(key.utf8))
            if case .found(let data) = storage.read(key) { hasher.update(data: data) } else { hasher.update(data: Data("<none>".utf8)) }
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    static func removeAll() {
        for key in allKeys { _ = storage.remove(key) }
    }

    static func log(_ line: String) {
        print("AFT-PROOF [\(phase)] \(line)")
    }
}

@Suite("Keychain guard proof (real keychain, multi-launch)", .serialized)
struct KeychainGuardProofTests {
    typealias F = GuardProofFixture

    @Test("seed: launch 1 reads every seeded profile and writes a refresh", .enabled(if: F.phase == "seed"))
    func seed() async throws {
        F.removeAll()
        let owners = F.collection(F.ownerNames, ids: F.ownerIDs)
        let fleet = F.collection(F.fleetNames, ids: F.fleetIDs)
        #expect(F.storage.add(try JSONEncoder().encode(owners), forKey: kTokenV3Profiles) == errSecSuccess)
        #expect(F.storage.add(try JSONEncoder().encode(fleet), forKey: kTokenV4Profiles) == errSecSuccess)
        #expect(F.storage.add(try JSONEncoder().encode(F.token("Personal")), forKey: kTokenV3) == errSecSuccess)
        #expect(F.storage.add(try JSONEncoder().encode(F.token("Production")), forKey: kTokenV4) == errSecSuccess)

        let store = TokenProfileStore(storage: F.storage)
        guard case .loaded(let readOwners) = await store.loadState(environment: .owner),
              case .loaded(let readFleet) = await store.loadState(environment: .fleet) else {
            Issue.record("launch 1 could not read the seeded items"); return
        }
        #expect(readOwners.profiles.map(\.name) == F.ownerNames)
        #expect(readFleet.profiles.map(\.name) == F.fleetNames)
        F.log("launch 1 read owners=\(readOwners.profiles.map(\.name)) fleet=\(readFleet.profiles.map(\.name))")

        // A refresh writes back to the active profile; the others are kept.
        try await store.updateActiveToken(F.token("Personal-refreshed"), environment: .owner)
        let after = await store.load(environment: .owner)
        #expect(after.profiles.count == 3)
        #expect(after.profiles.first?.token.access_token == "proof-access-Personal-refreshed")

        // Read-only census of the person's real items: keys only, no data.
        let census = KeychainWrapper.global.allKeys().sorted()
        F.log("read-only census of the real AuthForTesla items in group.global: \(census.count) keys \(census)")
        F.log("seeded + refreshed, fingerprint \(F.fingerprint())")
    }

    @Test("reread: launch 2 sees every profile and the refreshed token", .enabled(if: F.phase == "reread"))
    func reread() async throws {
        let store = TokenProfileStore(storage: F.storage)
        guard case .loaded(let owners) = await store.loadState(environment: .owner),
              case .loaded(let fleet) = await store.loadState(environment: .fleet) else {
            Issue.record("launch 2 could not read the items"); return
        }
        #expect(owners.profiles.map(\.id) == F.ownerIDs)
        #expect(fleet.profiles.map(\.id) == F.fleetIDs)
        #expect(owners.profiles.first?.token.access_token == "proof-access-Personal-refreshed")
        let mirror = F.storage.read(kTokenV3)
        guard case .found(let data) = mirror else { Issue.record("legacy mirror missing"); return }
        #expect(try JSONDecoder().decode(Token.self, from: data).access_token == "proof-access-Personal-refreshed")
        F.log("launch 2 read owners=\(owners.profiles.map(\.name)) fleet=\(fleet.profiles.map(\.name)); refreshed token persisted")
        F.log("FINGERPRINT \(F.fingerprint())")
    }

    @Test("noaccess: a Mac without group.global writes nothing", .enabled(if: F.phase == "noaccess"))
    func noAccess() async throws {
        let counting = CountingKeychainStorage(F.storage)
        let store = TokenProfileStore(storage: counting)

        let rawRead = F.storage.read(kTokenV3Profiles)
        F.log("raw read of the fixture without the entitlement: \(rawRead)")
        guard case .failed(let status) = rawRead else {
            Issue.record("expected the keychain to refuse the read, got \(rawRead)"); return
        }

        for environment in [LoginEnvironment.owner, .fleet] {
            guard case .unavailable(.unreadable(let reported)) = await store.loadState(environment: environment) else {
                Issue.record("the store did not report \(environment) unreadable"); return
            }
            #expect(reported == status)
        }

        let newProfile = TokenProfile(name: "Mac", token: F.token("mac"))
        await #expect(throws: TokenStoreError.self) { try await store.upsert(profile: newProfile, environment: .owner, makeActive: true) }
        await #expect(throws: TokenStoreError.self) { try await store.updateActiveToken(F.token("x"), environment: .owner) }
        await #expect(throws: TokenStoreError.self) { try await store.updateActiveToken(F.token("x"), environment: .fleet) }
        await #expect(throws: TokenStoreError.self) { try await store.updateProfileToken(id: F.ownerIDs[1], token: F.token("x"), environment: .owner) }
        await #expect(throws: TokenStoreError.self) { try await store.setActive(id: F.ownerIDs[2], environment: .owner) }
        await #expect(throws: TokenStoreError.self) { try await store.rename(id: F.fleetIDs[0], to: "x", environment: .fleet) }
        await #expect(throws: TokenStoreError.self) { try await store.delete(id: F.ownerIDs[0], environment: .owner) }
        await #expect(throws: TokenStoreError.self) { try await store.delete(id: F.fleetIDs[1], environment: .fleet) }
        await #expect(throws: TokenStoreError.self) { try await store.clearLegacyMirror(environment: .owner) }
        _ = await store.suggestedName(for: .owner)

        #expect(counting.writeAttempts.isEmpty, "writes attempted: \(counting.writeAttempts)")
        F.log("status \(status); every change refused; write attempts: \(counting.writeAttempts.count)")

        // The production configuration reports the same, read-only.
        let production = TokenProfileStore(storage: KeychainSyncedItemStorage(keychain: .global))
        if case .unavailable(let error) = await production.loadState(environment: .owner) {
            F.log("production store (read only): unavailable \(error)")
        } else {
            Issue.record("the production store read the synced items without the entitlement")
        }
    }

    @Test("verify: the fixture is byte-identical after the no-access launch", .enabled(if: F.phase == "verify"))
    func verify() async throws {
        let now = F.fingerprint()
        F.log("fingerprint now \(now), launch 2 \(F.expectedFingerprint)")
        #expect(!F.expectedFingerprint.isEmpty)
        #expect(now == F.expectedFingerprint)
        let store = TokenProfileStore(storage: F.storage)
        #expect(await store.load(environment: .owner).profiles.map(\.id) == F.ownerIDs)
        #expect(await store.load(environment: .fleet).profiles.map(\.id) == F.fleetIDs)
    }

    @Test("cleanup: the fixture is removed", .enabled(if: F.phase == "cleanup"))
    func cleanup() {
        F.removeAll()
        for key in F.allKeys { #expect(F.storage.read(key) == .notFound) }
        F.log("fixture removed")
    }
}
