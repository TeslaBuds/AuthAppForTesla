//
//  HomeView.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var model: AuthViewModel
    
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    
    var body: some View {
        
        VStack {
            HomeViewHeader(model: model)
            ScrollView {
            VStack {
                HomeViewToken(title: "Refresh Token", description: "A refresh token is a special kind of token used to obtain a renewed access token.", token: model.tokenV3?.refresh_token) {
                    model.donateRefreshTokenInteraction()
                }
                Divider()
                HomeViewToken(title: "Access Token", description: "Access tokens are used in token-based authentication to allow an application to access the Tesla API with your account.", token: model.tokenV2?.access_token) {
                    model.donateAccessTokenInteraction()
                }
            }
            .padding(.vertical, 15)
            HomeViewRefreshToken(model: model)
            }
//            Spacer()
            Text("V. \(version) build \(build)")
                .font(.system(size: 12, weight: .regular, design: .default))
                .multilineTextAlignment(.center)
                .foregroundColor(.gray)
        }.frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .bottom).padding()
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(model: AuthViewModel())
    }
}
