//
//  TokenWidgetView.swift
//  AuthForTeslaWidgets
//
//  Add this file to the "AuthForTeslaWidgets" widget extension target.
//

import SwiftUI
import WidgetKit

/// The visual layout rendered inside the widget.
struct TokenWidgetView: View {
    let entry: TokenWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallBody
        default:
            mediumBody
        }
    }

    // MARK: - Small widget (single token)

    private var smallBody: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image("SetupIcon")
                    .resizable()
                    .frame(width: 22, height: 22)
                    .clipShape(.rect(cornerRadius: 5))
                Spacer()
                Image(systemName: "steeringwheel")
                    .imageScale(.small)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if entry.v3HasToken {
                expiryLabel(expiresAt: entry.v3ExpiresAt, label: "Owners API")
            } else {
                Text("Not signed in")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }

    // MARK: - Medium widget (both tokens side by side)

    private var mediumBody: some View {
        HStack(spacing: 0) {
            tokenColumn(
                label: "Owners API",
                systemImage: "steeringwheel",
                hasToken: entry.v3HasToken,
                expiresAt: entry.v3ExpiresAt
            )
            Divider().padding(.vertical)
            tokenColumn(
                label: "Fleet API",
                systemImage: "car.2.fill",
                hasToken: entry.v4HasToken,
                expiresAt: entry.v4ExpiresAt
            )
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }

    private func tokenColumn(
        label: String,
        systemImage: String,
        hasToken: Bool,
        expiresAt: Date?
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(label, systemImage: systemImage)
                .font(.caption)
                .bold()
                .foregroundStyle(.primary)
                .lineLimit(1)
            Spacer()
            if hasToken {
                expiryLabel(expiresAt: expiresAt, label: label)
            } else {
                Text("Not signed in")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }

    // MARK: - Expiry label

    @ViewBuilder
    private func expiryLabel(expiresAt: Date?, label: String) -> some View {
        if let expiresAt {
            let isExpired = expiresAt < .now
            let isExpiringSoon = expiresAt.timeIntervalSinceNow < 3600

            VStack(alignment: .leading, spacing: 2) {
                Text(isExpired ? "Expired" : "Expires")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(expiresAt, style: .relative)
                    .font(.caption)
                    .bold()
                    .foregroundStyle(
                        isExpired ? .red :
                        isExpiringSoon ? .orange : .green
                    )
            }
        } else {
            Text("Active")
                .font(.caption)
                .bold()
                .foregroundStyle(.green)
        }
    }
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    TokenWidget()
} timeline: {
    TokenWidgetEntry.placeholder
}

#Preview(as: .systemMedium) {
    TokenWidget()
} timeline: {
    TokenWidgetEntry.placeholder
    TokenWidgetEntry(
        date: .now,
        v3HasToken: false,
        v3ExpiresAt: nil,
        v4HasToken: true,
        v4ExpiresAt: .now.addingTimeInterval(-60)
    )
}
