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
        .sheet(item: $authURL) { url in
            AuthWebView(url: url, redirectUrl: redirectUri) { result in
                handleAuthResult(result)
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
            ) else {
                model.showToast(.error("Could not build authorization URL. Check your credentials."))
                return
            }

            authURL = url
        }
    }

    private func handleAuthResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
            guard let code = urlComponents?.queryItems?.first(where: { $0.name == "code" })?.value else {
                authURL = nil
                model.showToast(.error("Sign-in failed: no authorization code received."))
                return
            }
            // Capture values before clearing sheet state
            let capturedRegion = region
            let capturedClientId = clientId
            let capturedSecret = clientSecret
            let capturedRedirectUri = redirectUri
            Task {
                let token = await AuthController.shared.exchangeCodeV4(
                    code,
                    region: capturedRegion,
                    fleetClientId: capturedClientId,
                    fleetSecret: capturedSecret,
                    fleetRedirectUri: capturedRedirectUri
                )
                if token != nil {
                    await model.loadTokens()
                } else {
                    model.showToast(.error("Sign-in failed: could not exchange authorization code."))
                }
                authURL = nil
            }
        case .failure(let error):
            model.showToast(.error("Sign-in failed: \(error.localizedDescription)"))
            authURL = nil
        }
    }
}

#Preview {
    LoginViewSignInFleetAPI(model: AuthViewModel())
}
