//
//  AboutView.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI

struct AboutView: View {
    @State private var isLicenseViewPresented = false

    var body: some View {
        IconBackgroundView {
            ScrollView {
                AboutViewHeader(isLicenseViewPresented: $isLicenseViewPresented)
                Spacer()
                AboutViewFooter()
                TipJarView()
                    .padding(.bottom)
            }
        }
        .navigationDestination(isPresented: $isLicenseViewPresented) {
            LicenseView()
        }
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
