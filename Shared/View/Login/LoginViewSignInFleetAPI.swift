//
//  LoginViewSignInFleetAPI.swift
//  AuthAppForTesla
//
//  Created by Nila on 20.02.21.
//

import SwiftUI
import TeslaAuthKit

struct LoginViewSignInFleetAPI: View {
    @Bindable var model: AuthViewModel
    /// When `true`, a successful sign-in creates a brand-new profile
    /// instead of replacing the active profile's token.
    var addAsNewProfile: Bool = false
    /// Local UI state for the form. Captured into the model's
    /// in-flight OAuth snapshot when "Sign in with Tesla" is tapped,
    /// so a parent view rebuild after the sheet opens can't lose them.
    @State private var region: TokenRegion = .global
    @State private var clientId = ""
    @State private var clientSecret = ""
    @State private var redirectUri = ""

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("Client ID").bold()
                TextField("Client ID", text: $clientId)
                    .neverAutocapitalized()
                    .autocorrectionDisabled()
                    .glassField()
                Text("Client Secret").bold()
                SecureField("Client Secret", text: $clientSecret)
                    .glassField()
                Text("Redirect URI").bold()
                TextField("Redirect URI", text: $redirectUri)
                    .neverAutocapitalized()
                    .autocorrectionDisabled()
                    .glassField()
            }
            .font(.footnote)

            Text("Choose login region")
            Picker("Region", selection: $region) {
                ForEach(TokenRegion.allCases) { region in
                    Text(region.rawValue.capitalized).tag(region)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()

            // No sign-out first: the stored profile is replaced only after
            // a successful code exchange (#49).
            Button("Sign in with Tesla") {
                authenticateV4(region: region, clientId: clientId, clientSecret: clientSecret, redirectUri: redirectUri)
            }
            .buttonStyle(.glass(.regular.tint(Color("TeslaRed"))))
            .foregroundStyle(.white)
            .accessibilityIdentifier("loginButtonv4")
            .padding(.top, AppSpacing.xs)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .task {
            clientId = await AuthController.shared.fleetClientId
            clientSecret = await AuthController.shared.fleetClientSecret
            redirectUri = await AuthController.shared.fleetRedirectUri
        }
        .sheet(item: $model.fleetAuth) { auth in
            AuthWebView(session: auth.session) { result in
                handleAuthResult(result, auth: auth)
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

            guard let request = await AuthController.shared.buildOAuthURLV4(
                region: region,
                fleetClientId: clientId,
                fleetRedirectUri: redirectUri
            ) else {
                model.showToast(.error("Could not build authorization URL. Check your credentials."))
                return
            }

            let session = TeslaAuthSession(url: request.url, redirectUrl: redirectUri)

            model.fleetAuth = FleetAuthInFlight(
                url: request.url,
                state: request.state,
                region: region,
                clientId: clientId,
                clientSecret: clientSecret,
                redirectUri: redirectUri,
                addAsNewProfile: addAsNewProfile,
                session: session
            )
        }
    }

    private func handleAuthResult(_ result: Result<URL, Error>, auth: FleetAuthInFlight) {
        switch result {
        case .success(let url):
            let code: String
            switch OAuthRedirect.authorizationCode(from: url, expectedState: auth.state) {
            case .success(let value):
                code = value
            case .failure(let error):
                model.fleetAuth = nil
                model.showToast(.error(LoginViewSignInOwnersAPI.message(for: error)))
                return
            }
            Task {
                let token = await AuthController.shared.exchangeCodeV4(
                    code,
                    region: auth.region,
                    fleetClientId: auth.clientId,
                    fleetSecret: auth.clientSecret,
                    fleetRedirectUri: auth.redirectUri,
                    addAsNewProfile: auth.addAsNewProfile
                )
                if token != nil {
                    await model.loadTokens()
                } else {
                    model.showToast(.error("Sign-in failed: could not exchange authorization code."))
                }
                model.fleetAuth = nil
            }
        case .failure(let error):
            model.showToast(.error("Sign-in failed: \(error.localizedDescription)"))
            model.fleetAuth = nil
        }
    }
}

#Preview {
    LoginViewSignInFleetAPI(model: AuthViewModel())
}
