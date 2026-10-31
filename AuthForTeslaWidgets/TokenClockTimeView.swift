//
//  TokenClockTimeView.swift
//  AuthForTeslaWidgets
//
//  The clock time a token expires, or expired. Static text, so it stays
//  right between the timeline's urgency entries without any reloads.
//

import SwiftUI
import WidgetKit

struct TokenClockTimeView: View {
    let status: TokenStatus

    var body: some View {
        if let expiresAt = status.expiresAt {
            Text("At \(expiresAt.formatted(date: .omitted, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
