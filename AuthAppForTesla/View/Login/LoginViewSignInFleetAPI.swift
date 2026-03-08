//
//  LoginViewSignInFleetAPI.swift
//  AuthAppForTesla
//
//  Created by Nila on 20.02.21.
//

import SwiftUI

struct LoginViewSignInFleetAPI: View {
    @Bindable var model: AuthViewModel
    @State private var region: TokenRegion = .global
    @State private var clientId = ""
    @State private var clientSecret = ""
    @State private var redirectUri = ""
    @State private var authURL: URL?
    @State private var showingAuth = false

    var body: some View {
        VStack {
            VStack {
                Text("Client ID").bold()
                TextField("Client ID", text: $clientId)
                    .textFieldStyle(.roundedBorder)
                Text("Client Secret").bold()
                SecureField("Client Secret", text: $clientSecret)
                    .textFieldStyle(.roundedBorder)
                Text("Redirect URI").bold()
                TextField("Redirect URI", text: $redirectUri)
                    .textFieldStyle(.roundedBorder)
            }
            .font(.footnote)

            Text("Choose login region")
            Picker("Region", selection: $region) {
                ForEach(TokenRegion.allCases) { region in
                    Text(region.rawValue.capitalized).tag(region)
                }
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 10)

            Button("Sign in with Tesla") {
                model.logOut(environment: .fleet)
                authenticateV4(region: region, clientId: clientId, clientSecret: clientSecret, redirectUri: redirectUri)
            }
            .buttonStyle(.glass(.regular.tint(Color("TeslaRed"))))
            .foregroundStyle(.white)
            .accessibilityIdentifier("loginButtonv4")
        }
        .padding(.horizontal, 35)
        .padding(.vertical, 20)
        .task {
            clientId = await AuthController.shared.fleetClientId
            clientSecret = await AuthController.shared.fleetClientSecret
            redirectUri = await AuthController.shared.fleetRedirectUri
        }
        .sheet(isPresented: $showingAuth) {
            if let authURL {
                AuthWebView(url: authURL, redirectUrl: redirectUri) { result in
                    handleAuthResult(result)
                }
            }
        }
    }

    private func authenticateV4(region: TokenRegion, clientId: String, clientSecret: String, redirectUri: String) {
        Task {
            await AuthController.shared.storeFleetConnection(
                clientId: clientId,
                clientSecret: clientSecret,
                redirectUri: redirectUri
            )

            guard let url = await AuthController.shared.buildOAuthURLV4(
                region: region,
                fleetClientId: clientId,
                fleetRedirectUri: redirectUri
            ) else { return }

            authURL = url
            showingAuth = true
        }
    }

    private func handleAuthResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
            guard let code = urlComponents?.queryItems?.first(where: { $0.name == "code" })?.value else {
                return
            }
            Task {
                _ = await AuthController.shared.exchangeCodeV4(
                    code,
                    region: region,
                    fleetClientId: clientId,
                    fleetSecret: clientSecret,
                    fleetRedirectUri: redirectUri
                )
                _ = await model.acquireTokenSilentV4(forceRefresh: true)
            }
        case .failure(let error):
            print("Authenticate V4 error: \(error.localizedDescription)")
        }
    }
}

#Preview {
    LoginViewSignInFleetAPI(model: AuthViewModel())
}
