//
//  LoginViewSignInOwnersAPI.swift
//  AuthAppForTesla
//
//  Created by Nila on 20.02.21.
//

import SwiftUI

struct LoginViewSignInOwnersAPI: View {
    @Bindable var model: AuthViewModel
    @State private var region: TokenRegion = .global
    @State private var authURL: URL?
    @State private var codeVerifier: String?

    var body: some View {
        VStack {
            Text("Choose login region")
            Picker("Region", selection: $region) {
                ForEach(TokenRegion.allCases) { region in
                    Text(region.rawValue.capitalized).tag(region)
                }
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 10)
            Button("Sign in with Tesla") {
                model.logOut(environment: .owner)
                authenticateV3()
            }
            .buttonStyle(.glass(.regular.tint(Color("TeslaRed"))))
            .foregroundStyle(.white)
            .accessibilityIdentifier("loginButton")
        }
        .padding(.horizontal, 35)
        .padding(.vertical, 20)
        .sheet(item: $authURL) { url in
            AuthWebView(url: url, redirectUrl: kTeslaRedirectUri) { result in
                handleAuthResult(result)
            }
        }
    }

    private func authenticateV3() {
        Task {
            guard let oauthInfo = await AuthController.shared.buildOAuthURLV3(
                region: region,
                redirectUrl: kTeslaRedirectUri
            ) else {
                print("[OwnersLogin] buildOAuthURLV3 returned nil")
                return
            }

            print("[OwnersLogin] OAuth URL built: \(oauthInfo.url.absoluteString.prefix(80))...")
            print("[OwnersLogin] Code verifier: \(oauthInfo.codeVerifier.prefix(10))...")
            codeVerifier = oauthInfo.codeVerifier
            authURL = oauthInfo.url
        }
    }

    private func handleAuthResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            print("[OwnersLogin] handleAuthResult SUCCESS - callback URL: \(url.absoluteString.prefix(100))...")
            let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
            let allParams = urlComponents?.queryItems?.map { "\($0.name)=\($0.value?.prefix(10) ?? "nil")..." } ?? []
            print("[OwnersLogin] Query params: \(allParams)")
            guard let code = urlComponents?.queryItems?.first(where: { $0.name == "code" })?.value else {
                print("[OwnersLogin] ERROR: No 'code' param found in callback URL")
                authURL = nil
                return
            }
            guard let verifier = codeVerifier else {
                print("[OwnersLogin] ERROR: codeVerifier is nil")
                authURL = nil
                return
            }
            print("[OwnersLogin] Code extracted: \(code.prefix(10))... | Verifier: \(verifier.prefix(10))...")
            // Capture values before clearing sheet state
            let capturedRegion = region
            print("[OwnersLogin] Starting token exchange for region: \(capturedRegion)")
            Task {
                let token = await AuthController.shared.exchangeCodeV3(code, codeVerifier: verifier, region: capturedRegion)
                print("[OwnersLogin] Token exchange result: \(token != nil ? "SUCCESS" : "FAILED (nil)")")
                if let token {
                    print("[OwnersLogin] Token type: \(token.token_type) | expires_in: \(token.expires_in) | refresh_token length: \(token.refresh_token.count)")
                    await model.loadTokens()
                    print("[OwnersLogin] model.loadTokens() complete | tokenV3 is nil: \(model.tokenV3 == nil)")
                }
                authURL = nil
            }
        case .failure(let error):
            print("[OwnersLogin] handleAuthResult FAILURE: \(error.localizedDescription)")
            authURL = nil
        }
    }
}

#Preview {
    LoginViewSignInOwnersAPI(model: AuthViewModel())
}
