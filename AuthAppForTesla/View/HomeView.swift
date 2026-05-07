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
    @State private var isAddingAccount = false
    let loginEnvironment: LoginEnvironment

    var body: some View {
        IconBackgroundView {
            ScrollView {
                VStack(spacing: AppSpacing.cardGap) {
                    HomeViewHeader(model: model, loginEnvironment: loginEnvironment) {
                        isAddingAccount = true
                    }
                    .padding(AppSpacing.cardInner)
                    .glassEffect(.clear, in: .rect(cornerRadius: AppCornerRadius.container))

                    VStack(spacing: AppSpacing.md) {
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
                        Divider()
                        Toggle("Show token details", isOn: $showDetails)
                            .font(.subheadline)
                    }
                    .padding(AppSpacing.cardInner)
                    .glassEffect(.clear, in: .rect(cornerRadius: AppCornerRadius.container))

                    HomeViewRefreshTokens(model: model)

                    TipJarView(scrollPosition: $scrollPosition)

                    AppVersionLabel()
                }
                .padding(.horizontal, AppSpacing.screenEdge)
                .padding(.top, AppSpacing.scrollTop)
                .padding(.bottom, AppSpacing.scrollBottom)
            }
            .scrollPosition($scrollPosition)
        }
        .sheet(isPresented: $isAddingAccount) {
            HomeViewAddAccountSheet(model: model, loginEnvironment: loginEnvironment, isPresented: $isAddingAccount)
        }
    }
}

private struct HomeViewAddAccountSheet: View {
    @Bindable var model: AuthViewModel
    let loginEnvironment: LoginEnvironment
    @Binding var isPresented: Bool
    @State private var initialProfileCount: Int?

    private var currentProfileCount: Int {
        switch loginEnvironment {
        case .owner: model.profilesV3.profiles.count
        case .fleet: model.profilesV4.profiles.count
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LoginViewHeader()
                Group {
                    switch loginEnvironment {
                    case .owner:
                        LoginViewSignInOwnersAPI(model: model, addAsNewProfile: true)
                    case .fleet:
                        LoginViewSignInFleetAPI(model: model, addAsNewProfile: true)
                    }
                }
                .fixedSize(horizontal: false, vertical: true)
            }
            .navigationTitle("Add Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                }
            }
            .task {
                if initialProfileCount == nil {
                    initialProfileCount = currentProfileCount
                }
            }
            .onChange(of: currentProfileCount) { _, newValue in
                if let initial = initialProfileCount, newValue > initial {
                    let collection = loginEnvironment == .owner ? model.profilesV3 : model.profilesV4
                    if let active = collection.activeProfile {
                        model.showToast(.success("Added account \"\(active.name)\"."))
                    }
                    isPresented = false
                }
            }
        }
    }
}

#Preview("Owners API – Populated") {
    HomeView(model: PreviewModelFactory.populatedModel(), loginEnvironment: .owner)
}

#Preview("Fleet API – Populated") {
    HomeView(model: PreviewModelFactory.populatedModel(), loginEnvironment: .fleet)
}

#Preview("Owners API – Empty") {
    HomeView(model: AuthViewModel(), loginEnvironment: .owner)
}
