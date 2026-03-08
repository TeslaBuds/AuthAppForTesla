//
//  TipJarView.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 08/03/2026.
//

import SwiftUI
import StoreKit

/// A compact, unobtrusive tip jar prompt that can be placed on any page.
/// Shows a friendly message with three tip buttons (coffee, dinner, night out).
struct TipJarView: View {
    @State private var tipManager = TipJarManager()
    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 12) {
            tipHeader
            if isExpanded {
                tipButtons
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding()
        .glassEffect(.clear, in: .rect(cornerRadius: 24))
        .padding(.horizontal)
        .animation(.snappy, value: isExpanded)
        .task {
            await tipManager.loadProducts()
        }
        .sensoryFeedback(.success, trigger: tipManager.recentlyTipped)
    }

    private var tipHeader: some View {
        Button {
            isExpanded.toggle()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: tipManager.recentlyTipped ? "heart.fill" : "heart")
                    .font(.title3)
                    .foregroundStyle(Color("TeslaRed"))
                    .contentTransition(.symbolEffect(.replace))

                VStack(alignment: .leading, spacing: 2) {
                    if tipManager.recentlyTipped {
                        Text("Thank you for your support!")
                            .font(.subheadline)
                            .bold()
                    } else {
                        Text("Enjoying Auth for Tesla?")
                            .font(.subheadline)
                            .bold()
                        Text("Show some love for years of free updates")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .rotationEffect(.degrees(isExpanded ? 180 : 0))
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var tipButtons: some View {
        if tipManager.isLoading {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        } else if tipManager.products.isEmpty {
            Text("Tips unavailable right now")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else {
            HStack(spacing: 12) {
                ForEach(tipManager.products, id: \.id) { product in
                    TipButton(product: product, tipManager: tipManager)
                }
            }
        }
    }
}

/// An individual tip button showing the tier icon, label, and price.
private struct TipButton: View {
    let product: Product
    var tipManager: TipJarManager

    @State private var isPurchasing = false

    private var label: (title: String, icon: String) {
        TipJarManager.tipLabels[product.id] ?? ("Tip", "heart.fill")
    }

    var body: some View {
        Button {
            guard !isPurchasing else { return }
            isPurchasing = true
            Task {
                await tipManager.purchase(product)
                isPurchasing = false
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: label.icon)
                    .font(.title2)
                Text(label.title)
                    .font(.caption)
                    .bold()
                Text(product.displayPrice)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
        }
        .buttonStyle(.glass(.regular.tint(Color("TeslaRed"))))
        .foregroundStyle(.white)
        .disabled(isPurchasing)
        .overlay {
            if isPurchasing {
                ProgressView()
            }
        }
    }
}

#Preview {
    IconBackgroundView {
        TipJarView()
    }
}
