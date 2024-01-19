//
//  HomeViewHeader.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI

struct HomeViewHeader: View {
    @ObservedObject var model: AuthViewModel
    let loginEnvironment: LoginEnvironment
    
    var body: some View {
        HStack {
            VStack(alignment:. leading) {
                Text(loginEnvironment == .owner ? "Owners API" : "Fleet API")
                    .font(.title)
                    .fontWeight(.bold)
                let token = loginEnvironment == .owner ? model.tokenV3 : model.tokenV4
                Text("Access Token valid for ").font(.subheadline) + Text(token?.expires_at ?? Date.distantPast, style: .relative)
                    .font(.subheadline)
            }
            Spacer()
            Menu {
                Button("Logout", action: {
                    model.logOut(environment: loginEnvironment)
                })
                    .accessibilityIdentifier("logoutButton")
            } label: {
                Image(systemName: "person.crop.circle")
                    .foregroundColor(Color("TeslaRed"))
                    .font(.system(size: 30))
                    .accessibilityIdentifier("homeMenu")
            }
        }
    }
}

struct HomeViewHeader_Previews: PreviewProvider {
    static var previews: some View {
        HomeViewHeader(model: AuthViewModel(), loginEnvironment: .owner)
        HomeViewHeader(model: AuthViewModel(), loginEnvironment: .fleet)
    }
}
