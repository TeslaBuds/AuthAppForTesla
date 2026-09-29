//
//  TipJarStoreKitTests.swift
//  Auth for Tesla Tests
//

import Testing
import Foundation
import StoreKit
import StoreKitTest
@testable import AuthAppForTesla

/// Exercises the tip jar end to end against `TipJarProducts.storekit`:
/// all three consumables load in price order, and a purchase succeeds and
/// finishes its transaction. Nothing is gated, so there is nothing to restore.
@Suite("Tip jar (StoreKit test session)", .serialized)
@MainActor
struct TipJarStoreKitTests {

    private func makeSession() throws -> SKTestSession {
        let url = try #require(Bundle.main.url(forResource: "TipJarProducts", withExtension: "storekit"))
        let session = try SKTestSession(contentsOf: url)
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
        return session
    }

    @Test("Three tip consumables load, sorted by price")
    func productsLoad() async throws {
        let session = try makeSession()
        defer { session.clearTransactions() }

        let manager = TipJarManager()
        await manager.loadProducts()

        #expect(manager.errorMessage == nil)
        #expect(manager.products.map(\.id) == TipJarManager.productIDs)
        #expect(manager.products.allSatisfy { $0.type == .consumable })
        #expect(manager.products.allSatisfy { TipJarManager.tipLabels[$0.id] != nil })
    }

    // `SKTestSession.buyProduct(identifier:)` is not available on Mac Catalyst.
    #if !targetEnvironment(macCatalyst)
    @Test("Each tip can be bought and yields a verified consumable transaction")
    func purchaseSucceeds() async throws {
        let session = try makeSession()
        defer { session.clearTransactions() }

        for id in TipJarManager.productIDs {
            let transaction = try await session.buyProduct(identifier: id)
            #expect(transaction.productID == id)
            #expect(transaction.productType == .consumable)
            await transaction.finish()
        }
        #expect(session.allTransactions().count == TipJarManager.productIDs.count)
    }
    #endif
}
