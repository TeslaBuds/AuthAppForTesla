//
//  HomeView.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI

struct HomeView: View {
    @Bindable var model: AuthViewModel
    @State private var showDetails = false
    @State private var scrollPosition = ScrollPosition()
    let loginEnvironment: LoginEnvironment

    var body: some View {
        IconBackgroundView {
            ScrollView {
                HomeViewHeader(model: model, loginEnvironment: loginEnvironment)
                    .padding(.horizontal)
                    .padding(.top)

                VStack {
                    let token = loginEnvironment == .owner ? model.tokenV3 : model.tokenV4
                    HomeViewToken(
                        title: "Refresh Token (Recommended)",
                        description: "A refresh token allows for continuous interaction with your Tesla Account and is usually what is requested by other apps and third-party services. This is used to generate new access tokens.",
                        token: token,
                        tokenTypeToShow: .refreshToken,
                        loginEnvironment: loginEnvironment,
                        showDetails: showDetails
                    )
                    Divider()
                    HomeViewToken(
                        title: "Access Token",
                        description: "An access token allows for temporary access to your Tesla Account and typically expires after several hours.",
                        token: token,
                        tokenTypeToShow: .accessToken,
                        loginEnvironment: loginEnvironment,
                        showDetails: showDetails
                    )
                    .opacity(0.5)
                    Divider()
                    Toggle("Show token details", isOn: $showDetails)
                        .font(.headline)
                        .padding(.horizontal)
                }
                .padding(.vertical)
                .glassEffect(.clear, in: .rect(cornerRadius: 24))
                .padding()

                HomeViewRefreshTokens(model: model)

                TipJarView(scrollPosition: $scrollPosition)

                AppVersionLabel()
                    .padding()
            }
            .scrollPosition($scrollPosition)
        }
    }
}

#Preview("Owners API") {
    HomeView(model: AuthViewModel(), loginEnvironment: .owner)
}

#Preview("Fleet API") {
    HomeView(model: AuthViewModel(), loginEnvironment: .fleet)
}
