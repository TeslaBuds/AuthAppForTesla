//
//  InlineTokenWidgetView.swift
//  AuthForTeslaWidgets
//
//  Lock Screen inline: the primary API's glyph and its short status.
//

import SwiftUI
import WidgetKit

struct InlineTokenWidgetView: View {
    let entry: TokenWidgetEntry

    var body: some View {
        let api = TokenAPI.primary(in: entry)
        Label {
            TokenShortStatusText(status: api.status(in: entry), date: entry.date)
        } icon: {
            Image(systemName: api.systemImage)
        }
    }
}
