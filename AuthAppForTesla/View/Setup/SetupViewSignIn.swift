//
//  SetupViewSignIn.swift
//  AuthAppForTesla
//
//  Created by Nila on 20.02.21.
//

import SwiftUI
import OAuthSwift

struct SetupViewSignIn: View {
    @ObservedObject var model: AuthViewModel
    @State var region: TokenRegion = .global
    
    var body: some View {
        VStack {
            Picker(selection: $region, label: Text("Region: \(self.region.rawValue.capitalized)").frame(maxWidth: .infinity).foregroundColor(Color("TeslaRed"))) {
                ForEach(TokenRegion.allCases) { region in
                    Text("\(region.rawValue.capitalized)").tag(region)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .frame(maxWidth: .infinity)
            .padding(.bottom, 10)
            Button("Sign in with Tesla", action: {
                model.logOut()
                self.authenticateV3()
            })
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .bottom)
            .padding(.vertical, 15)
            .foregroundColor(Color.white)
            .background(Color("TeslaRed"))
            .cornerRadius(10.0)
        }
        .padding(.horizontal, 35)
        .padding(.vertical, 20)
    }
    
    var oauthswiftGlobal = OAuth2Swift(
        consumerKey: "ownerapi",
        consumerSecret: kTeslaSecret,
        authorizeUrl: "https://auth.tesla.com/oauth2/v3/authorize",
        accessTokenUrl: "",
        responseType: "code"
    )
    
    var oauthswiftChina = OAuth2Swift(
        consumerKey: "ownerapi",
        consumerSecret: kTeslaSecret,
        authorizeUrl: "https://auth.tesla.cn/oauth2/v3/authorize",
        accessTokenUrl: "",
        responseType: "code"
    )
    
    private func verifier(forKey key: String) -> String {
        let verifier = key.data(using: .utf8)!.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
        return verifier
    }
    
    private func challenge(forVerifier verifier: String) -> String {
        let hash = verifier.sha256
        let challenge = hash.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
        return challenge
    }
    
    
    var credential: OAuthSwiftCredential?
    
    var oauthswift: OAuth2Swift {
        switch self.region {
        case .global:
            return oauthswiftGlobal
        case.china:
            return oauthswiftChina
        }
    }
    
    func authenticateV3() {
        
        AuthController.shared().getAuthRegion(region: self.region) { (url) in
            guard let url = url else { return }
            
            oauthswift.accessTokenUrl = url
            
            DispatchQueue.main.async {
                let codeVerifier = self.verifier(forKey: kTeslaClientID)
                let codeChallenge = self.challenge(forVerifier: codeVerifier)
                
                let internalController = AuthWebViewController()
                oauthswift.authorizeURLHandler = internalController
                let state = generateState(withLength: 20)
                
                oauthswift.authorize(withCallbackURL: "https://auth.tesla.com/void/callback", scope: "openid email offline_access", state: state, codeChallenge: codeChallenge, codeChallengeMethod: "S256", codeVerifier: codeVerifier) { result in
                    switch result {
                    case .success(let (credential, _, _)):
                        print(credential.oauthToken)
                        
                        let token = Token(access_token: credential.oauthToken, token_type: "bearer", expires_in: 300, refresh_token: credential.oauthRefreshToken, expires_at: credential.oauthTokenExpiresAt, region: self.region)//  Date().addingTimeInterval(TimeInterval(3888000))) //credential.oauthTokenExpiresAt ??
                        model.setJwtToken(token)
                        model.acquireTokenSilent(forceRefresh: true) { (token) in
                        }
                    case .failure(let error):
                        print(error)
                    }
                }
            }
            
        }
    }
}

struct SetupViewSignIn_Previews: PreviewProvider {
    static var previews: some View {
        SetupViewSignIn(model: AuthViewModel())
    }
}
