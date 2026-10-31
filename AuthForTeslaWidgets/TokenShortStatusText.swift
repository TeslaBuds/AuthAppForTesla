//
//  TokenShortStatusText.swift
//  AuthForTeslaWidgets
//
//  A token's status in a few words for the Lock Screen: the clock time it
//  expires, "Expired" or "Signed out". Static, so no reloads between entries.
//

import SwiftUI
import WidgetKit

struct TokenShortStatusText: View {
    let status: TokenStatus
    let date: Date

    var body: some View {
        switch (status.urgency(at: date), status.expiresAt) {
        case (.signedOut, _):
            Text("Signed out")
        case (.expired, _):
            Text("Expired")
        case (_, let expiresAt?):
            Text(expiresAt.formatted(date: .omitted, time: .shortened))
                .monospacedDigit()
        case (_, nil):
            Text("Signed in")
        }
    }
}
