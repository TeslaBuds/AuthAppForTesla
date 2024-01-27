//
//  HomeView.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var model: AuthViewModel
    let loginEnvironment: LoginEnvironment
    
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    
    var body: some View {
        
        VStack() {
            HomeViewHeader(model: model, loginEnvironment: loginEnvironment)
                .padding(.horizontal)
            ScrollView {
                VStack {
                    let token = loginEnvironment == .owner ? model.tokenV3 : model.tokenV4
                    HomeViewToken(title: "Refresh Token (Recommended)", description: "A refresh token allows for continuous interaction with your Tesla Account and is usually what is requested by other apps and third-party services. This is used to generate new access tokens.", token: token, tokenTypeToShow: .refreshToken, loginEnvironment: loginEnvironment)
                    Divider()
                    HomeViewToken(title: "Access Token", description: "An access token allows for temporary access to your Tesla Account and typically expires after several hours.", token: token, tokenTypeToShow: .accessToken, loginEnvironment: loginEnvironment)
                        .opacity(0.5)
                }
                .padding(.vertical, 15)
                HomeViewRefreshTokens(model: model)
                    .padding(.horizontal)
                Text("v. \(version) build \(build)")
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
                    .padding()
            }
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .bottom)
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView(model: AuthViewModel(), loginEnvironment: .owner)
        HomeView(model: AuthViewModel(), loginEnvironment: .fleet)
    }
}
