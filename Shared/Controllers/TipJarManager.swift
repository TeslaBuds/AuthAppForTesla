//
//  TipJarManager.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 08/03/2026.
//

import StoreKit
import TeslaAuthKit

/// Manages in-app tip jar products and purchases using StoreKit 2.
@MainActor
@Observable
class TipJarManager {
    /// The available tip products, sorted by price.
    var products: [Product] = []
    /// Whether products are currently being loaded.
    var isLoading = false
    /// Why the last load or purchase failed. `TipJarView` shows it under
    /// the buttons; the next attempt clears it (#54).
    var errorMessage: String?
    /// Set briefly after a successful purchase to trigger thank-you feedback.
    var recentlyTipped = false

    /// Product identifiers for the three tip tiers.
    /// These must match the IDs configured in App Store Connect.
    static let productIDs: [String] = [
        "dk.kimhansen.AuthAppForTesla.SmallTip",
        "dk.kimhansen.AuthAppForTesla.MediumTip",
        "dk.kimhansen.AuthAppForTesla.LargeTip"
    ]

    /// Human-friendly labels for each tip tier, keyed by product ID.
    static let tipLabels: [String: (title: String, icon: String)] = [
        "dk.kimhansen.AuthAppForTesla.SmallTip": ("Coffee", "cup.and.saucer.fill"),
        "dk.kimhansen.AuthAppForTesla.MediumTip": ("Dinner", "fork.knife"),
        "dk.kimhansen.AuthAppForTesla.LargeTip": ("Night Out", "party.popper.fill")
    ]

    /// Loads products from the App Store; tests substitute a failing one.
    private let productLoader: @MainActor ([String]) async throws -> [Product]

    init(productLoader: @escaping @MainActor ([String]) async throws -> [Product] = { try await Product.products(for: $0) }) {
        self.productLoader = productLoader
    }

    /// Fetches tip products from the App Store.
    func loadProducts() async {
        guard products.isEmpty else { return }
        isLoading = true
        errorMessage = nil

        do {
            let storeProducts = try await productLoader(Self.productIDs)
            products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            errorMessage = String(localized: "Unable to load tips. Check your connection and try again.")
        }

        isLoading = false
    }

    /// Initiates a purchase for the given product.
    func purchase(_ product: Product) async {
        errorMessage = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                recentlyTipped = true
                // Reset after a short delay
                try? await Task.sleep(for: .seconds(3))
                recentlyTipped = false
            case .userCancelled:
                break
            case .pending:
                break
            @unknown default:
                break
            }
        } catch StoreError.verificationFailed {
            errorMessage = String(localized: "The App Store couldn't verify this tip. Check your purchase history before trying again.")
        } catch {
            errorMessage = String(localized: "The tip didn't go through. Please try again.")
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.verificationFailed
        case .verified(let safe):
            return safe
        }
    }
}

/// Errors related to StoreKit operations.
enum StoreError: LocalizedError {
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .verificationFailed:
            "Transaction verification failed."
        }
    }
}
