//
//  AboutViewHeader.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI

struct AboutViewHeader: View {
    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            Spacer()
            Image("SetupIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)
                .clipShape(.rect(cornerRadius: AppCornerRadius.small))
                .shadow(radius: 6)
                .padding(.bottom, AppSpacing.sm)
            Text("Auth for Tesla")
                .font(.largeTitle)
                .bold()
            AppVersionLabel()
                .font(.subheadline)
            Text("\u{00A9} 2026 Kim Hansen, Michael Teuscher")
                .font(.subheadline)
            NavigationLink {
                LicenseView()
            } label: {
                Text("Open Source Licenses")
            }
            .buttonStyle(.glass(.regular.tint(Color("TeslaRed"))))
            .foregroundStyle(.white)
            .font(.subheadline)
            .padding(.top, AppSpacing.sm)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
}

#Preview {
    NavigationStack {
        AboutViewHeader()
    }
}
