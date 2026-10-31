//
//  LargeTokenWidgetView.swift
//  AuthForTeslaWidgets
//
//  The large tile (cards stacked) and the extra-large / full-page tile (cards
//  side by side), Kemmey/DRSFramer#71. Each API gets a card with its hero
//  expiry and the clock time it expires, which the smaller sizes leave out.
//

import SwiftUI
import WidgetKit

struct LargeTokenWidgetView: View {
    let entry: TokenWidgetEntry
    let axis: Axis

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image("SetupIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 32, height: 32)
                    .clipShape(.rect(cornerRadius: 7))
                    .accessibilityHidden(true)
                Text("Access Tokens")
                    .font(.headline)
                    .foregroundStyle(Color("TeslaRed"))
                    .widgetAccentable()
            }
            let layout = axis == .vertical
                ? AnyLayout(VStackLayout(alignment: .leading))
                : AnyLayout(HStackLayout(alignment: .top))
            layout {
                ForEach(TokenAPI.allCases, id: \.self) { api in
                    TokenCardView(api: api, entry: entry)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
