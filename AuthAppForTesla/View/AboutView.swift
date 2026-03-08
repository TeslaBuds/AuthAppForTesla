//
//  AboutView.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        IconBackgroundView {
            ScrollView {
                AboutViewHeader()
                Spacer()
                AboutViewFooter()
                TipJarView()
                    .padding(.bottom)
            }
        }
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
