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

    /// The parent scroll view's position, used to scroll the tip buttons
    /// into view when expanded.
    var scrollPosition: Binding<ScrollPosition>?

    var body: some View {
        VStack(spacing: 12) {
            tipHeader
            if isExpanded {
                tipButtons
                    .transition(.blurReplace)
            }
        }
        .padding()
        .glassEffect(.clear, in: .rect(cornerRadius: 24))
        .padding(.horizontal)
        .animation(.snappy, value: isExpanded)
        .id(TipJarView.scrollID)
        .onChange(of: isExpanded) {
            if isExpanded {
                withAnimation(.snappy) {
                    scrollPosition?.wrappedValue.scrollTo(
                        id: TipJarView.scrollID,
                        anchor: .bottom
                    )
                }
            }
        }
        .task {
            await tipManager.loadProducts()
        }
        .sensoryFeedback(.success, trigger: tipManager.recentlyTipped)
    }

    /// Stable identity for scroll targeting.
    static let scrollID = "tipJar"

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
            TipButtonLabel(
                title: label.title,
                icon: label.icon,
                displayPrice: product.displayPrice
            )
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

/// The visual content of a tip button, showing an icon, title, and price.
/// Extracted so the layout can be previewed without a StoreKit `Product`.
struct TipButtonLabel: View {
    let title: String
    let icon: String
    let displayPrice: String

    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: icon)
                .font(.title3)
            Text(title)
                .font(.caption)
                .bold()
            Text(displayPrice)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }
}

#Preview {
    IconBackgroundView {
        TipJarView()
    }
}

#Preview("Tip Buttons") {
    IconBackgroundView {
        HStack(spacing: 12) {
            ForEach(Array(TipJarManager.tipLabels), id: \.key) { id, label in
                Button {
                } label: {
                    TipButtonLabel(
                        title: label.title,
                        icon: label.icon,
                        displayPrice: "$\(id.hasSuffix("SmallTip") ? "2.99" : id.hasSuffix("MediumTip") ? "9.99" : "24.99")"
                    )
                }
                .buttonStyle(.glass(.regular.tint(Color("TeslaRed"))))
                .foregroundStyle(.white)
            }
        }
        .padding(.horizontal)
    }
}
