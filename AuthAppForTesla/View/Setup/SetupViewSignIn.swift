//
//  SetupViewSignIn.swift
//  AuthAppForTesla
//
//  Created by Nila on 20.02.21.
//

import SwiftUI
import OAuthSwift
import CryptoKit

struct SetupViewSignIn: View {
    @ObservedObject var model: AuthViewModel
    @State var region: TokenRegion = .global
    
    var body: some View {
        
        // unfortunately the "onAppear modifier" is not called "properly"
        // therefore we have this ugly workaround here
        if model.externalTokenRequest != nil {
            DispatchQueue.main.async {
                self.authenticateV3()
            }
        }
        
        return VStack {
            
            
            Text("Choose login region")
            Picker("", selection: $region) {
                ForEach(TokenRegion.allCases) { region in
                    Text("\(NSLocalizedString(region.rawValue.capitalized, comment: ""))").tag(region)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            
            //            Picker(selection: $region, label: Text("Region: \(self.region.rawValue.capitalized)").frame(maxWidth: .infinity).foregroundColor(Color("TeslaRed"))) {
            //                ForEach(TokenRegion.allCases) { region in
            //                    Text("\(region.rawValue.capitalized)").tag(region)
            //                }
            //            }
            //            .pickerStyle(MenuPickerStyle())
            //            .frame(maxWidth: .infinity)
            .padding(.bottom, 10)
            Button("Sign in with Tesla", action: {
#if DEBUG
                if CommandLine.arguments.contains("enable-testing") {
                    for arg in CommandLine.arguments {
                        if arg.starts(with: "token:") {
                            let tokenArg = arg.replacingOccurrences(of: "token:", with: "")
                            let token = Token(access_token: "", token_type: "bearer", expires_in: 300, refresh_token: tokenArg, expires_at: Date.future(), region: TokenRegion.global)
                            model.setJwtToken(token)
                            model.acquireTokenSilent(forceRefresh: true) { (token) in
                            }
                            return
                        }
                    }
                }
#endif
                model.logOut()
                self.authenticateV3()
            })
                .accessibilityIdentifier("loginButton")
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .bottom)
                .padding(.vertical, 15)
                .foregroundColor(Color.white)
                .background(Color("TeslaRed"))
                .cornerRadius(10.0)
                .disabled(model.externalTokenRequest != nil)
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
    
    private func verifier() -> String {
        let verifier = "\(Date().toISO())\(Date().toISO())\(Date().toISO())".data(using: .utf8)!.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
            .prefix(43)
        return String(verifier)

//        let verifier = key.data(using: .utf8)!.base64EncodedString()
//            .replacingOccurrences(of: "+", with: "-")
//            .replacingOccurrences(of: "/", with: "_")
//            .replacingOccurrences(of: "=", with: "")
//            .trimmingCharacters(in: .whitespaces)
//        return verifier
    }
    
    private func challenge(forVerifier verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        let base64 = Data(hash).base64EncodedString()
        let urlSafe = base64
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
        return urlSafe
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
                let codeVerifier = self.verifier()
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
                        
                        if let externalTokenRequest = model.externalTokenRequest {
                            
                            let responseURLString = String(format: externalTokenRequest.appDescription.responseURLTemplate,
                                                     token.refresh_token,
                                                     externalTokenRequest.appData)
                            if let responseURL = URL(string: responseURLString) {
                                UIApplication.shared.open(responseURL)
                            }
                        }
                    case .failure(let error):
                        print(error)
                    }
                    model.externalTokenRequest = nil
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
