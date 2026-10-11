//
//  InMemoryTokenStorage.swift
//  Auth for Tesla Tests
//
//  Test doubles: a synced-item storage held in memory, and a Tesla token
//  endpoint that never leaves the process.
//

import Foundation
import Synchronization
import TeslaAuthKit
@testable import AuthAppForTesla

/// The token store's storage, in memory. Never touches the keychain.
final class InMemoryTokenStorage: SyncedItemStorage, Sendable {
    private let items: Mutex<[String: Data]>
    private let readFailure: Mutex<OSStatus?> = Mutex(nil)

    init(_ items: [String: Data] = [:]) {
        self.items = Mutex(items)
    }

    /// Makes every read fail, like a keychain this signature can't open.
    func failReads(with status: OSStatus) { readFailure.withLock { $0 = status } }

    func value(_ key: String) -> Data? { items.withLock { $0[key] } }

    func read(_ key: String) -> KeychainReadResult {
        if let status = readFailure.withLock({ $0 }) { return .failed(status) }
        return items.withLock { $0[key] }.map(KeychainReadResult.found) ?? .notFound
    }

    func add(_ data: Data, forKey key: String) -> OSStatus {
        items.withLock { items in
            guard items[key] == nil else { return errSecDuplicateItem }
            items[key] = data
            return errSecSuccess
        }
    }

    func replace(_ data: Data, forKey key: String) -> OSStatus {
        items.withLock { items in
            guard items[key] != nil else { return errSecItemNotFound }
            items[key] = data
            return errSecSuccess
        }
    }

    func remove(_ key: String) -> OSStatus {
        items.withLock { items in
            items[key] == nil ? errSecItemNotFound : { items[key] = nil; return errSecSuccess }()
        }
    }
}

/// Tesla's token endpoint, stubbed: answers every refresh with `answer`.
struct StubTokenEndpoint: TokenRefreshTransport {
    let answer: @Sendable (String) -> TokenEndpointResponse

    func refresh(refreshToken: String, region: TokenRegion, environment: LoginEnvironment) async -> TokenEndpointResponse {
        answer(refreshToken)
    }
}

/// An `AuthController` over in-memory storage, a stub endpoint, and a
/// throwaway widget suite. Nothing real is read, written or called.
struct ControllerFixture {
    let storage: InMemoryTokenStorage
    let summary = SummaryFixture()
    let controller: AuthController
    let ownersId = UUID()
    let fleetId = UUID()

    static func token(_ refresh: String, expiresAt: Date) -> Token {
        Token(access_token: "a-\(refresh)", token_type: "bearer", expires_in: 28800,
              refresh_token: refresh, expires_at: expiresAt, region: .global)
    }

    static let staleExpiry = Date(timeIntervalSince1970: 1_900_000_000)

    init(answer: @escaping @Sendable (String) -> TokenEndpointResponse = { .token(ControllerFixture.token("\($0)-new", expiresAt: .now.addingTimeInterval(28800))) }) throws {
        let owners = TokenProfile(id: ownersId, name: "Personal", token: Self.token("RT3", expiresAt: Self.staleExpiry))
        let fleet = TokenProfile(id: fleetId, name: "Work", token: Self.token("RT4", expiresAt: Self.staleExpiry))
        storage = InMemoryTokenStorage([
            kTokenV3Profiles: try JSONEncoder().encode(TokenProfileCollection(profiles: [owners], activeProfileId: owners.id)),
            kTokenV4Profiles: try JSONEncoder().encode(TokenProfileCollection(profiles: [fleet], activeProfileId: fleet.id))
        ])
        controller = AuthController(
            store: TokenProfileStore(storage: storage),
            transport: StubTokenEndpoint(answer: answer),
            ledger: InMemoryRejectionLedger(),
            retryDelay: .zero,
            summaryWriter: TokenSummaryWriter(publisher: summary.publisher)
        )
    }
}
