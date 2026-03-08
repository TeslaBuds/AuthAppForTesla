//
//  AboutView.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        NavigationStack {
            IconBackgroundView {
                ScrollView {
                    AboutViewHeader()
                        .padding(.top, 50)
                    Spacer()
                    AboutViewFooter()
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }
}

#Preview {
    AboutView()
}
