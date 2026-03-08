//
//  AboutViewHeader.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI

struct AboutViewHeader: View {
    @State private var isLicenseViewPresented = false

    var body: some View {
        VStack {
            Spacer()
            Image("SetupIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)
                .clipShape(.rect(cornerRadius: 10))
                .shadow(radius: 6)
            Text("Auth for Tesla")
                .font(.largeTitle)
                .bold()
                .padding(.bottom, 0.5)
            AppVersionLabel()
                .font(.subheadline)
            Text("\u{00A9} 2026 Kim Hansen, Michael Teuscher")
                .font(.subheadline)
            Button("Open Source Licenses") {
                isLicenseViewPresented = true
            }
            .buttonStyle(.glass(.regular.tint(Color("TeslaRed"))))
            .foregroundStyle(.white)
            .font(.subheadline)
            .padding(.top, 5)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .navigationDestination(isPresented: $isLicenseViewPresented) {
            LicenseView()
        }
    }
}

#Preview {
    NavigationStack {
        AboutViewHeader()
    }
}
