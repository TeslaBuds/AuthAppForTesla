//
//  HomeViewHeader.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI

struct HomeViewHeader: View {
    var model: AuthViewModel
    let loginEnvironment: LoginEnvironment
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(loginEnvironment == .owner ? "Owners API" : "Fleet API")
                    .font(.title)
                    .bold()
                let token = loginEnvironment == .owner ? model.tokenV3 : model.tokenV4
                let expiresLabel = Text("Access Token valid for ").font(.subheadline)
                let expiresDate = Text(token?.expires_at ?? Date.distantPast, style: .relative).font(.subheadline)
                Text("\(expiresLabel)\(expiresDate)")
            }
            Spacer()
            Menu("Account", systemImage: "person.crop.circle") {
                Button("Logout") {
                    model.logOut(environment: loginEnvironment)
                }
                .accessibilityIdentifier("logoutButton")
            }
            .labelStyle(.iconOnly)
            .foregroundStyle(Color("TeslaRed"))
            .font(.title)
            .accessibilityIdentifier("homeMenu")
        }
    }
}

#Preview("Owners") {
    HomeViewHeader(model: AuthViewModel(), loginEnvironment: .owner)
}

#Preview("Fleet") {
    HomeViewHeader(model: AuthViewModel(), loginEnvironment: .fleet)
}
