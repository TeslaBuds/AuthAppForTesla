//
//  SetupViewSignIn.swift
//  AuthAppForTesla
//
//  Created by Nila on 20.02.21.
//

import SwiftUI
import CryptoKit

struct LoginViewSignInOwnersAPI: View {
    @ObservedObject var model: AuthViewModel
    @State var region: TokenRegion = .global
    
    var body: some View {
        return VStack {
            
            
            Text("Choose login region")
            Picker("", selection: $region) {
                ForEach(TokenRegion.allCases) { region in
                    Text("\(NSLocalizedString(region.rawValue.capitalized, comment: ""))").tag(region)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.bottom, 10)
            Button("Sign in with Tesla", action: {
#if DEBUG
                if CommandLine.arguments.contains("enable-testing") {
                    for arg in CommandLine.arguments {
                        if arg.starts(with: "token:") {
                            let tokenArg = arg.replacingOccurrences(of: "token:", with: "")
                            let token = Token(access_token: "", token_type: "bearer", expires_in: 300, refresh_token: tokenArg, expires_at: Date.future(), region: TokenRegion.global)
                            model.setJwtToken(token)
                            model.acquireTokenSilentV3(forceRefresh: true) { (token) in
                            }
                            return
                        }
                    }
                }
#endif
                model.logOut(environment: .owner)
                self.authenticateV3()
            })
                .accessibilityIdentifier("loginButton")
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .bottom)
                .padding(.vertical, 15)
                .foregroundColor(Color.white)
                .background(Color("TeslaRed"))
                .cornerRadius(10.0)
//                .disabled(model.externalTokenRequest != nil)
        }
        .padding(.horizontal, 35)
        .padding(.vertical, 20)
    }
    
    func authenticateV3() {
        DispatchQueue.main.async {
            if let vc = AuthController.shared().authenticateWeb(region: self.region, redirectUrl: kTeslaRedirectUri, completion: { (result) in
                switch result {
                case .success(let token):
                    model.acquireTokenSilentV3(forceRefresh: true) { (token) in
                    }
//                    if let externalTokenRequest = model.externalTokenRequest {
//                        
//                        let responseURLString = String(format: externalTokenRequest.appDescription.responseURLTemplate,
//                                                 token.refresh_token,
//                                                 externalTokenRequest.appData)
//                        if let responseURL = URL(string: responseURLString) {
//                            UIApplication.shared.open(responseURL)
//                        }
//                    }
                case .failure(let error):
                    print("Authenticate V3 error: \(error.localizedDescription)")
                }
            }) {
                UIApplication.topViewController?.present(vc, animated: true, completion: nil)
            }
        }
    }
}

struct LoginViewSignInOwnersAPI_Previews: PreviewProvider {
    static var previews: some View {
        LoginViewSignInOwnersAPI(model: AuthViewModel())
    }
}
