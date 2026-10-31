//
//  RectangularTokenWidgetView.swift
//  AuthForTeslaWidgets
//
//  Lock Screen rectangular: one line per API — glyph, name, urgency glyph and
//  the clock time it expires.
//

import SwiftUI
import WidgetKit

struct RectangularTokenWidgetView: View {
    let entry: TokenWidgetEntry

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(TokenAPI.allCases, id: \.self) { api in
                let status = api.status(in: entry)
                HStack {
                    TokenUrgencySymbol(urgency: status.urgency(at: entry.date))
                    Text(api.title)
                        .bold()
                    Spacer(minLength: 0)
                    TokenShortStatusText(status: status, date: entry.date)
                }
                .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
