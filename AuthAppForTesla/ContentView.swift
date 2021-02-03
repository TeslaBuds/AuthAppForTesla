//
//  ContentView.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

//import SwiftUI
//
//struct ContentView: View {
//    var body: some View {
//        Text("Hello, world!")
//            .padding()
//    }
//}
//
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}

import Foundation
import SwiftUI
import Combine
import OAuthSwift
import SwiftDate

struct ContentView: View {
    @ObservedObject var model: AuthViewModel
    
    @State var username = ""
    @State var password = ""
    @State var message = ""
    @State var loading = false
    @State var showRequestLog = false
    
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""

    var body: some View {
        ScrollView {
            VStack (alignment: .leading, spacing: 8) {
                if (message.count > 0)
                {
                    Text(message)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.red)
                    Divider()
                }
                                
                Group {
                Spacer()
                Button(action: {
                    model.logOut()
                    self.authenticateV3()
                }, label: {
                    Text("Login with Tesla")
                }).frame(maxWidth: .infinity)
                Spacer()
                }

                
                if (model.tokenV3?.refresh_token.count ?? 0 > 0) {
                    Button(action: {
                        let pasteBoard = UIPasteboard.general
                        pasteBoard.string = model.tokenV3?.refresh_token
                    }, label: {
                        Text("Refresh token")
                    }).frame(maxWidth: .infinity)
                }

                if (model.tokenV2?.access_token.count ?? 0 > 0) {
                    Button(action: {
                        let pasteBoard = UIPasteboard.general
                        pasteBoard.string = model.tokenV2?.access_token
                    }, label: {
                        Text("Access token")
                    }).frame(maxWidth: .infinity)
                }
            
                if (message.count > 0)
                {
                    Divider()
                    Text(message)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.red)
                    Divider()
                }

                Group {
                    Text("v. \(self.version) build \(self.build)").font(.footnote).foregroundColor(.gray).frame(maxWidth: .infinity, alignment: .center)
                        .onTapGesture {
                            self.showRequestLog.toggle()
                        }
                    
                    if (self.showRequestLog)
                    {
                        Text("Authentication events")
                        VStack (alignment: .leading) {
                            ForEach(getRequestEventLog()) { event in
                                Text("\(DateInRegion(event.when, region: Region.local).toString(DateToStringStyles.time(DateFormatter.Style.short))): \(event.message)")
                                    .fixedSize(horizontal: false, vertical: true)
                                    .multilineTextAlignment(.leading)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }

            }.disabled(loading)
        }
        .navigationBarTitle("Login")
    }

    var oauthswift = OAuth2Swift(
        consumerKey: "ownerapi",
        consumerSecret: kTeslaSecret,
        authorizeUrl: "https://auth.tesla.com/oauth2/v3/authorize",
        accessTokenUrl: "https://auth.tesla.com/oauth2/v3/token",
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
    
    func authenticateV3() {
        let codeVerifier = self.verifier(forKey: kTeslaClientID)
        let codeChallenge = self.challenge(forVerifier: codeVerifier)
        
        let internalController = AuthWebViewController()
        //        internalController.callbackURL = "https://auth.tesla.com/void/callback"
        //        internalController.callingViewController = self
        oauthswift.authorizeURLHandler = internalController
        //        oauthswift.authorizeURLHandler = SafariURLHandler(viewController: self, oauthSwift: oauthswift)
        let state = generateState(withLength: 20)
        
        oauthswift.authorize(withCallbackURL: "https://auth.tesla.com/void/callback", scope: "openid email offline_access", state: state, codeChallenge: codeChallenge, codeChallengeMethod: "S256", codeVerifier: codeVerifier) { result in
            switch result {
            case .success(let (credential, _, _)):
                print(credential.oauthToken)
                
                let token = Token(access_token: credential.oauthToken, token_type: "bearer", expires_in: 300, refresh_token: credential.oauthRefreshToken, expires_at: credential.oauthTokenExpiresAt)//  Date().addingTimeInterval(TimeInterval(3888000))) //credential.oauthTokenExpiresAt ??
                model.setJwtToken(token)
                model.acquireTokenSilent(forceRefresh: true) { (token) in
                    //
                }
//                AuthController.shared().getVehicles({ (vehicles, message) in
//                    if (vehicles != nil)
//                    {
//                        self.loading = false
//                        TeslaController.shared().startPolling()
//                        self.model.loggedIn = true
//                    }
//                })
            case .failure(let error):
                print(error)
            }
        }
    }
    
    func getData() {
        oauthswift.startAuthorizedRequest("https://owner-api.teslamotors.com/api/1/vehicles", method: .GET, parameters: OAuthSwift.Parameters()) { (result) in
            print(result)
        }
    }
}
