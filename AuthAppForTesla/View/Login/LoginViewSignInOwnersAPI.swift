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
    /// Region picker selection. Local @State is fine — once the user
    /// taps "Sign in with Tesla" the value is captured into the
    /// model's in-flight OAuth snapshot, so a parent rebuild after
    /// the sheet opens can't lose it.
    @State private var region: TokenRegion = .global

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Text("Choose login region")
            Picker("Region", selection: $region) {
                ForEach(TokenRegion.allCases) { region in
                    Text(region.rawValue.capitalized).tag(region)
                }
            }
            .pickerStyle(.segmented)
            Button("Sign in with Tesla") {
                if !addAsNewProfile {
                    model.logOut(environment: .owner)
                }
                authenticateV3()
            }
            .buttonStyle(.glass(.regular.tint(Color("TeslaRed"))))
            .foregroundStyle(.white)
            .accessibilityIdentifier("loginButton")
            .padding(.top, AppSpacing.xs)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .sheet(item: $model.ownersAuth) { auth in
            AuthWebView(session: auth.session) { result in
                handleAuthResult(result, auth: auth)
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

            let session = TeslaAuthSession(
                url: oauthInfo.url,
                redirectUrl: kTeslaRedirectUri
            )

            model.ownersAuth = OwnersAuthInFlight(
                url: oauthInfo.url,
                codeVerifier: oauthInfo.codeVerifier,
                region: region,
                addAsNewProfile: addAsNewProfile,
                session: session
            )
        }
    }

    private func handleAuthResult(_ result: Result<URL, Error>, auth: OwnersAuthInFlight) {
        switch result {
        case .success(let url):
            logOAuth("redirect URL: \(url.absoluteString)")
            let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true)
            logOAuth("query items: \(String(describing: urlComponents?.queryItems))")
            guard let code = urlComponents?.queryItems?.first(where: { $0.name == "code" })?.value else {
                logOAuth("no code in redirect — query was: \(String(describing: urlComponents?.query))")
                model.ownersAuth = nil
                model.showToast(.error("Sign-in failed: no authorization code received."))
                return
            }
            logOAuth("extracted code prefix: \(String(code.prefix(20)))… length=\(code.count)")
            logOAuth("codeVerifier length=\(auth.codeVerifier.count) prefix=\(String(auth.codeVerifier.prefix(10)))…")
            Task {
                let token = await AuthController.shared.exchangeCodeV3(
                    code,
                    codeVerifier: auth.codeVerifier,
                    region: auth.region,
                    addAsNewProfile: auth.addAsNewProfile
                )
                logOAuth("exchangeCodeV3 returned \(token == nil ? "nil" : "token \(String(token!.access_token.prefix(20)))…")")
                if token != nil {
                    await model.loadTokens()
                } else {
                    model.showToast(.error("Sign-in failed: could not exchange authorization code."))
                }
                model.ownersAuth = nil
            }
        case .failure(let error):
            logOAuth("auth result failure: \(error)")
            model.showToast(.error("Sign-in failed: \(error.localizedDescription)"))
            model.ownersAuth = nil
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
