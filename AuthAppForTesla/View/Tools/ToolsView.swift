//
//  ToolsView.swift
//  AuthAppForTesla
//
//  Hub screen that lists the developer tools shipped with the app —
//  JWT inspector, snippet exporter, and the API test panel. Matches
//  the visual language of HomeView (IconBackgroundView backdrop,
//  glass cards, TeslaRed accents) so the Tools tab doesn't feel like
//  a different app when the user switches to it.
//

import SwiftUI

struct ToolsView: View {
    @Bindable var model: AuthViewModel

    var body: some View {
        IconBackgroundView {
            ScrollView {
                VStack(spacing: AppSpacing.cardGap) {
                    ToolsHeaderCard()

                    VStack(spacing: 0) {
                        ToolsRow(
                            icon: "checkmark.shield.fill",
                            title: "Test Your Token",
                            subtitle: "Run read-only API calls to verify your stored token works end-to-end.",
                            destination: .testToken
                        )
                        Divider()
                        ToolsRow(
                            icon: "magnifyingglass.circle.fill",
                            title: "JWT Inspector",
                            subtitle: "Decode any JWT into its header, payload, scopes, and expiry.",
                            destination: .jwtInspector
                        )
                        Divider()
                        ToolsRow(
                            icon: "curlybraces",
                            title: "Snippet Exporter",
                            subtitle: "Generate ready-to-paste cURL, HTTPie, Swift, and Python snippets.",
                            destination: .snippetExporter
                        )
                    }
                    .glassCard()
                }
                .padding(.top, AppSpacing.scrollTop)
                .padding(.bottom, AppSpacing.scrollBottom)
            }
        }
        .navigationTitle("Tools")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ToolsHeaderCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("Tools")
                .font(.title)
                .bold()
            Text("Diagnostic and developer tools that work with your stored Owners or Fleet API tokens.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .glassCard()
    }
}

private struct ToolsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let destination: ToolsDestination

    var body: some View {
        NavigationLink(value: destination) {
            HStack(spacing: AppSpacing.md) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(Color("TeslaRed"))
                    .frame(width: 34)
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(.rect)
            .padding(.vertical, AppSpacing.sm)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
        .accessibilityIdentifier(title)
    }
}

enum ToolsDestination: Hashable {
    case jwtInspector
    case snippetExporter
    case testToken
}

#Preview {
    NavigationStack {
        ToolsView(model: AuthViewModel())
    }
}
