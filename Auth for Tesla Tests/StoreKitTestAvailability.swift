//
//  StoreKitTestAvailability.swift
//  Auth for Tesla Tests
//

import Testing
import Foundation
import StoreKit
import StoreKitTest
@testable import AuthAppForTesla

/// Whether `SKTestSession` can actually drive the StoreKit test daemon on
/// this simulator.
///
/// Xcode 27 cannot install a `.storekit` configuration on an iOS 26.x
/// simulator runtime: the session logs `SKInternalErrorDomain Code=3` for
/// every save, reset and clear, StoreKit silently falls back to the Sandbox
/// environment, and `buyProduct` throws `.notEntitled`. That reads like a
/// broken tip jar but is the wrong runtime. The same build passes on iOS 27.
/// So the StoreKit suite probes once and skips with a reason rather than
/// failing with a misleading error. Recipe: DRSFramer `docs/storekit-testing.md`.
enum StoreKitTestAvailability {

    static let skipReason: Comment = """
        SKTestSession cannot reach the StoreKit test daemon on this simulator runtime \
        (buyProduct throws .notEntitled). Run StoreKit tests on a simulator whose iOS \
        major version matches the Xcode SDK — see DRSFramer docs/storekit-testing.md.
        """

    /// Buys one consumable through a throwaway session. Only `.notEntitled`
    /// means "unavailable"; any other outcome lets the real tests run and
    /// report it.
    @MainActor
    static func sessionCanTransact() async -> Bool {
        #if targetEnvironment(macCatalyst)
        return true
        #else
        guard let url = Bundle.main.url(forResource: "TipJarProducts", withExtension: "storekit"),
              let session = try? SKTestSession(contentsOf: url),
              let productID = TipJarManager.productIDs.first else { return true }
        session.resetToDefaultState()
        session.disableDialogs = true
        session.clearTransactions()
        defer { session.clearTransactions() }
        do {
            let transaction = try await session.buyProduct(identifier: productID)
            await transaction.finish()
            return true
        } catch StoreKitError.notEntitled {
            return false
        } catch {
            return true
        }
        #endif
    }
}
