//
//  SetupViewSignIn.swift
//  AuthAppForTesla
//
//  Created by Nila on 20.02.21.
//

import SwiftUI
import CryptoKit

struct LoginViewSignInFleetAPI: View {
    @ObservedObject var model: AuthViewModel
    @State var region: TokenRegion = .global
    @State var clientId = ""
    @State var clientSecret = ""
    @State var redirectUri = ""
    
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
            Picker("", selection: $region) {
                ForEach(TokenRegion.allCases) { region in
                    Text("\(NSLocalizedString(region.rawValue.capitalized, comment: ""))").tag(region)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.bottom, 10)
            
            Button("Sign in with Tesla", action: {
                model.logOut(environment: .fleet)
                self.authenticateV4(region: region, clientId: clientId, clientSecret: clientSecret, redirectUri: redirectUri)
            })
            .accessibilityIdentifier("loginButtonv4")
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .bottom)
            .padding(.vertical, 15)
            .foregroundColor(Color.white)
            .background(Color("TeslaRed"))
            .cornerRadius(10.0)
//            .disabled(model.externalTokenRequest != nil)
        }
        .padding(.horizontal, 35)
        .padding(.vertical, 20)
        .onAppear {
            clientId = AuthController.shared.fleetClientId
            clientSecret = AuthController.shared.fleetClientSecret
            redirectUri = AuthController.shared.fleetRedirectUri
        }
    }
    
    func authenticateV4(region: TokenRegion, clientId: String, clientSecret: String, redirectUri: String) {
        AuthController.shared.storeFleetConnection(clientId: clientId, clientSecret: clientSecret, redirectUri: redirectUri)
        DispatchQueue.main.async {
            if let vc = AuthController.shared.authenticateWebV4(region: region, fleetClientId: clientId, fleetSecret: clientSecret, fleetRedirectUri: redirectUri, completion: { (result) in
                switch result {
                case .success:
                    Task {
                        await model.acquireTokenSilentV4(forceRefresh: true)
                    }
                case .failure(let error):
                    print("Authenticate V4 error: \(error.localizedDescription)")
                }
            }) {
                UIApplication.topViewController?.present(vc, animated: true, completion: nil)
            }
        }
    }
}

struct LoginViewSignInFleetAPI_Previews: PreviewProvider {
    static var previews: some View {
        LoginViewSignInFleetAPI(model: AuthViewModel())
    }
}
