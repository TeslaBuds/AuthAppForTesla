//
//  TokenCardView.swift
//  AuthForTeslaWidgets
//
//  One API's card in the large and extra-large tiles.
//

import SwiftUI
import WidgetKit

struct TokenCardView: View {
    let api: TokenAPI
    let entry: TokenWidgetEntry

    var body: some View {
        let status = api.status(in: entry)
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                TokenAPILabel(api: api)
                Spacer(minLength: 0)
                TokenUrgencySymbol(urgency: status.urgency(at: entry.date))
                    .font(.title3)
            }
            Spacer(minLength: 0)
            TokenExpiryView(status: status, date: entry.date)
            TokenClockTimeView(status: status)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(.fill.tertiary, in: .containerRelative)
    }
}
