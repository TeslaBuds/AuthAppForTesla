//
//  CircularTokenWidgetView.swift
//  AuthForTeslaWidgets
//
//  Lock Screen circular: the primary API's glyph over its urgency glyph.
//  Urgency only changes at the timeline's entries, so nothing goes stale.
//

import SwiftUI
import WidgetKit

struct CircularTokenWidgetView: View {
    let entry: TokenWidgetEntry

    var body: some View {
        let api = TokenAPI.primary(in: entry)
        ZStack {
            AccessoryWidgetBackground()
            VStack {
                Image(systemName: api.systemImage)
                    .font(.caption)
                    .accessibilityHidden(true)
                TokenUrgencySymbol(urgency: api.status(in: entry).urgency(at: entry.date))
                    .font(.title3)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
