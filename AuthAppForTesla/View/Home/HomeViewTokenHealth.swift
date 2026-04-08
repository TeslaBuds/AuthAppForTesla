//
//  HomeViewTokenHealth.swift
//  AuthAppForTesla
//
//  Compact countdown showing how long the access token is still valid
//  for, plus the last successful refresh time when known. Sits at the
//  top of the home screen so the user can see token health at a glance.
//

import SwiftUI

struct HomeViewTokenHealth: View {
    let token: Token

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: statusSymbol)
                    .foregroundStyle(statusColor)
                Group {
                    let label = Text("\(statusVerb) ").font(.subheadline)
                    let when = Text(token.expires_at ?? .distantPast, style: .relative).font(.subheadline.bold())
                    Text("\(label)\(when)")
                }
            }
            if let lastRefreshed = token.expires_at?.addingTimeInterval(-TimeInterval(token.expires_in)) {
                Text("Last refreshed \(lastRefreshed.formatted(date: .abbreviated, time: .shortened))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var isExpired: Bool {
        (token.expires_at ?? .distantPast) <= Date()
    }

    private var statusVerb: String {
        isExpired ? "Expired" : "Valid for"
    }

    private var statusSymbol: String {
        isExpired ? "exclamationmark.triangle.fill" : "checkmark.seal.fill"
    }

    private var statusColor: Color {
        isExpired ? Color("TeslaRed") : .green
    }
}

#Preview("Valid") {
    HomeViewTokenHealth(token: Token(
        access_token: "a",
        token_type: "bearer",
        expires_in: 28800,
        refresh_token: "r",
        expires_at: Date().addingTimeInterval(7200),
        region: .global
    ))
}

#Preview("Expired") {
    HomeViewTokenHealth(token: Token(
        access_token: "a",
        token_type: "bearer",
        expires_in: 28800,
        refresh_token: "r",
        expires_at: Date().addingTimeInterval(-3600),
        region: .global
    ))
}
