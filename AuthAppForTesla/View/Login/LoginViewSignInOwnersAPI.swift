//
//  LoginViewSignInOwnersAPI.swift
//  AuthAppForTesla
//
//  Created by Nila on 20.02.21.
//

import SwiftUI
import os

private let aftOAuthLogger = Logger(subsystem: "dk.kimhansen.AuthAppForTesla", category: "oauth")

struct LoginViewSignInOwnersAPI: View {
    @Bindable var model: AuthViewModel
    /// When `true`, a successful sign-in creates a brand-new profile
    /// instead of replacing the active profile's token.
    var addAsNewProfile: Bool = false
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
                if !addAsNewProfile {
                    model.logOut(environment: .owner)
                }
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
                return
            }

            codeVerifier = oauthInfo.codeVerifier
            authURL = oauthInfo.url
        }
    }

    private func handleAuthResult(_ result: Result<URL, Error>) {
        switch result {
        case .success(let url):
            logOAuth("redirect URL: \(url.absoluteString)")
            let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
            logOAuth("query items: \(String(describing: urlComponents?.queryItems))")
            guard let code = urlComponents?.queryItems?.first(where: { $0.name == "code" })?.value else {
                logOAuth("no code in redirect — query was: \(String(describing: urlComponents?.query))")
                authURL = nil
                model.showToast(.error("Sign-in failed: no authorization code received."))
                return
            }
            logOAuth("extracted code prefix: \(String(code.prefix(20)))… length=\(code.count)")
            guard let verifier = codeVerifier else {
                logOAuth("codeVerifier was nil at handleAuthResult time")
                authURL = nil
                model.showToast(.error("Sign-in failed: missing code verifier."))
                return
            }
            logOAuth("codeVerifier length=\(verifier.count) prefix=\(String(verifier.prefix(10)))…")
            let capturedRegion = region
            let capturedAddAsNew = addAsNewProfile
            Task {
                let token = await AuthController.shared.exchangeCodeV3(code, codeVerifier: verifier, region: capturedRegion, addAsNewProfile: capturedAddAsNew)
                logOAuth("exchangeCodeV3 returned \(token == nil ? "nil" : "token \(String(token!.access_token.prefix(20)))…")")
                if token != nil {
                    await model.loadTokens()
                } else {
                    model.showToast(.error("Sign-in failed: could not exchange authorization code."))
                }
                authURL = nil
            }
        case .failure(let error):
            logOAuth("auth result failure: \(error)")
            model.showToast(.error("Sign-in failed: \(error.localizedDescription)"))
            authURL = nil
        }
    }

    private func logOAuth(_ message: String) {
        #if DEBUG
        aftOAuthLogger.notice("[AFT-OAUTH] \(message)")
        LiveTestLog.shared.append(message)
        #endif
    }
}

#Preview {
    LoginViewSignInOwnersAPI(model: AuthViewModel())
}
