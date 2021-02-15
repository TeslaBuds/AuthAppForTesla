//
//  ContentView.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import Foundation
import SwiftUI
import Combine
import OAuthSwift
import SwiftDate
import Networking


// A modifier that animates a font through various sizes.
struct AnimatableCustomFontModifier: AnimatableModifier {
    var size: CGFloat
    
    var animatableData: CGFloat {
        get { size }
        set { size = newValue }
    }
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: size))
    }
}

// To make that easier to use, I recommend wrapping
// it in a `View` extension, like this:
extension View {
    func animatableFont(size: CGFloat) -> some View {
        self.modifier(AnimatableCustomFontModifier(size: size))
    }
}


struct ContentView: View {
    @ObservedObject var model: AuthViewModel
    
    @State var username = ""
    @State var password = ""
    @State var message = ""
    @State var loading = false
    @State var showRequestLog = false
    @State var region: TokenRegion = .global
    @State private var fontSize: CGFloat = 32
    @State private var checkOpacity: Double = 0
    
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    
    fileprivate func animateCheck() {
        fontSize = 32
        checkOpacity = 1
        
        withAnimation(Animation.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.3)) {
            fontSize = 144
        }
        withAnimation(Animation.easeIn(duration: 0.2).delay(0.4)) {
            checkOpacity = 0
        }
    }
    
    var body: some View {
        ZStack{
            GeometryReader { proxy in
                RadialGradient(gradient: Gradient(colors: [Color(UIColor(named: "BackgroundGradientStart")!), Color(UIColor(named: "BackgroundGradientEnd")!)]), center: .center, startRadius: .zero, endRadius: proxy.size.most)
                    .edgesIgnoringSafeArea(.all)
            }
            
            ScrollView {
                VStack (spacing: 8) {
                    Group {
                        Text("Auth app for Tesla")
                        Text("v. \(self.version) build \(self.build)").font(.footnote).foregroundColor(.gray).frame(maxWidth: .infinity, alignment: .center)
                        
                    }
                }
                .padding(.top)
                
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
                    
                    if (model.tokenV3?.refresh_token.count ?? 0 == 0)
                    {
                        Group {
                            Button(action: {
                                model.logOut()
                                self.authenticateV3()
                            }, label: {
                                Text("Login with Tesla").frame(maxWidth: .infinity)
                            })
                            .frame(maxWidth: .infinity)
                            .padding()
                            .modifier(LightBackground())
                            
                            VStack {
                                Picker(selection: $region, label: Text("Region: \(self.region.rawValue.capitalized)").frame(maxWidth: .infinity)) {
                                    ForEach(TokenRegion.allCases) { region in
                                        Text("\(region.rawValue.capitalized)").tag(region)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(maxWidth: .infinity)
                            }
                            .padding()
                            .modifier(LightBackground())
                        }
                    }
                    else
                    {
                        Button(action: {
                            model.logOut()
                        }, label: {
                            Text("Logout").frame(maxWidth: .infinity)
                        })
                        .frame(maxWidth: .infinity)
                        .padding()
                        .modifier(LightBackground())
                    }
                    
                    if (model.tokenV3?.refresh_token.count ?? 0 > 0) {
                        Button(action: {
                            let pasteBoard = UIPasteboard.general
                            pasteBoard.string = model.tokenV3?.refresh_token
                            animateCheck()
                            model.donateRefreshTokenInteraction()
                        }, label: {
                            VStack {
                                Text("Copy refresh token")
                                Text("\(model.tokenV3?.access_token ?? "")")
                                    .font(.caption2)
                                    .lineLimit(1)
                                    .padding(.top, 2)
                            }.frame(maxWidth: .infinity)
                        })
                        .frame(maxWidth: .infinity)
                        .padding()
                        .modifier(LightBackground())
                    }
                    
                    if (model.tokenV2?.access_token.count ?? 0 > 0) {
                        Button(action: {
                            let pasteBoard = UIPasteboard.general
                            pasteBoard.string = model.tokenV2?.access_token
                            animateCheck()
                            model.donateAccessTokenInteraction()
                        }, label: {
                            VStack {
                                Text("Copy access token")
                                Group {
                                    Text("Valid for ") + Text(model.tokenV2?.expires_at ?? Date.distantPast, style: .relative)
                                }
                                .padding(.top, 2)
                                Text("\(model.tokenV2?.access_token ?? "")")
                                    .font(.caption2)
                                    .lineLimit(1)
                                    .padding(.top, 2)
                            }
                            .frame(maxWidth: .infinity)
                        })
                        .frame(maxWidth: .infinity)
                        .padding()
                        .modifier(LightBackground())
                    }
                    
                    if (model.tokenV3?.refresh_token.count ?? 0 > 0) {
                        Button(action: {
                            model.refreshAll()
                        }, label: {
                            VStack {
                                Text("Refresh tokens")
                            }.frame(maxWidth: .infinity)
                        })
                        .frame(maxWidth: .infinity)
                        .padding()
                        .modifier(LightBackground())
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
                    
                    Spacer()
                    
                    Group {
                        Text("v. \(self.version) build \(self.build)").font(.footnote).foregroundColor(.gray).frame(maxWidth: .infinity, alignment: .center)
                            .onTapGesture {
                                self.showRequestLog.toggle()
                            }
                        
                        if (self.showRequestLog)
                        {
                            Text("Authentication events")
                            
                            Text(getRequestEventText())
                                .fixedSize(horizontal: false, vertical: true)
                                .multilineTextAlignment(.leading)
                                .foregroundColor(.gray)
                        }
                    }
                    
                }.disabled(loading)
                .padding()
            }
            .navigationBarTitle("Auth app for Tesla")
            .navigationBarHidden(true)
            
            Group {
                Image(systemName: "checkmark.seal")
                    .foregroundColor(Color(UIColor(named: "AccentColor")!))
                    .animatableFont(size: fontSize)
                    .opacity(checkOpacity)
            }
        }
        
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
