//
//  HonestFailureTests.swift
//  Auth for Tesla Tests
//
//  #54: a refused Fleet credentials write is reported, never "Saved";
//  tip-jar load and purchase failures reach the screen.
//

import Testing
import Foundation
import TeslaAuthKit
@testable import AuthAppForTesla

@Suite("Failures are surfaced (#54)")
@MainActor
struct HonestFailureTests {
    let credentials = FleetCredentials(clientId: "id", clientSecret: "secret", redirectUri: "https://example.com/cb")

    @Test("Fleet credentials are not written, and the reason is thrown, when the synced items can't be read")
    func fleetStoreThrowsWhenUnreadable() {
        let storage = InMemoryTokenStorage()
        storage.failReads(with: errSecInteractionNotAllowed)
        var writes: [String] = []

        #expect(throws: TokenStoreError.unreadable(errSecInteractionNotAllowed)) {
            try credentials.store(read: storage.read) { _, key in writes.append(key); return true }
        }
        #expect(writes.isEmpty)
    }

    @Test("A failed keychain write is thrown, not reported as saved")
    func fleetStoreThrowsOnWriteFailure() {
        let storage = InMemoryTokenStorage()
        #expect(throws: TokenStoreError.writeFailed(errSecIO)) {
            try credentials.store(read: storage.read) { _, _ in false }
        }
    }

    @Test("Readable items are written, all three")
    func fleetStoreWritesWhenReadable() throws {
        let storage = InMemoryTokenStorage()
        var written: [String: String] = [:]
        try credentials.store(read: storage.read) { value, key in written[key] = value; return true }
        #expect(written == [kFleetClientID: "id", kFleetClientSecret: "secret", kFleetRedirectUri: "https://example.com/cb"])
    }

    @Test("A tip list that fails to load says so")
    func tipLoadFailureIsReported() async {
        let manager = TipJarManager(productLoader: { _ in throw URLError(.notConnectedToInternet) })
        await manager.loadProducts()
        #expect(manager.errorMessage != nil)
        #expect(manager.products.isEmpty)
        #expect(!manager.isLoading)
    }
}

/// Whether the stub purchaser fails.
@MainActor
final class PurchaseSwitch {
    var isOn = true
}
