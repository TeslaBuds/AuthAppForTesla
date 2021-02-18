//
//  AboutView.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 17/02/2021.
//

import Foundation
import SwiftUI
import StoreKit
import SafariServices

struct AppView: View {
    let name: String
    let appId: String?
    let appUrl: String?
    let icon: String

    @State var showSafari = false
    @State var showProduct = false
    @State var overlayAppID = ""
    @State var safariUrl = ""

    var body: some View {
        VStack{
            Image(icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .cornerRadius(12)
                .frame(width: 60)
            Text(name)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(theme.backgroundColor2))
        .cornerRadius(8)
        .shadow(radius: theme.shadow)

        .onTapGesture {
            if let appId = appId
            {
                overlayAppID = appId
                showProduct = true
            }
            else if let appUrl = appUrl
            {
                safariUrl = appUrl
                showSafari = true
            }
        }
        .background(
            Group {
                ViewControllerBridge(isActive: $showSafari, parameter: $safariUrl) { vc, active, parameter in
                    if active {
                        let safariVC = SFSafariViewController(url: URL(string: parameter)!)
                        vc.present(safariVC, animated: true) {
                            // Set the variable to false when the user dismisses the safari VC
                            self.showSafari = false
                        }
                    }
                }
                .frame(width: 0, height: 0)
                
                ViewControllerBridge(isActive: $showProduct, parameter: $overlayAppID) { vc, active, parameter in
                    if active {
                        let product = SKStoreProductViewController()
                        //product.delegate = context.coordinator
                        
                        let parameters = [ SKStoreProductParameterITunesItemIdentifier : parameter]
                        //isLoaded = false
                        product.loadProduct(withParameters: parameters) { (loaded, error) in
                            if loaded {
                                //      isLoaded = true
                            }
                        }
                        
                        vc.present(product, animated: true) {
                            // Set the variable to false when the user dismisses the VC
                            self.showProduct = false
                        }
                    }
                }
                .frame(width: 0, height: 0)
            }
        )
    }
}

struct Friend {
    let name: String
    let appId: String?
    let appUrl: String?
    let icon: String
}

struct AboutView: View {
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    
    @State var showRequestLog = false
    
    let friends = [
        Friend(name: "Watch app for Tesla", appId: "1512108917", appUrl: nil, icon: "WatchAppForTesla"),
        Friend(name: "TeSlate", appId: "1532406445", appUrl: nil, icon: "TeSlate"),
        Friend(name: "Charged — for Tesl‪a", appId: "1444906703", appUrl: nil, icon: "Charged"),
        Friend(name: "Teslascope", appId: nil, appUrl: "https://teslascope.com", icon: "Teslascope")
    ]
    
    var body: some View {
        ZStack{
            GeometryReader { proxy in
                RadialGradient(gradient: Gradient(colors: [Color(UIColor(named: "BackgroundGradientStart")!), Color(UIColor(named: "BackgroundGradientEnd")!)]), center: .center, startRadius: .zero, endRadius: proxy.size.most)
                    .edgesIgnoringSafeArea(.all)
            }
            
            ScrollView {
                VStack (spacing: 8) {
                    Group {
                        Image("AppStencil")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60)
                            .padding(.top,  20)
                        Text("Auth app for Tesla")
//                        Text("v. \(self.version) build \(self.build)").font(.footnote).foregroundColor(.gray).frame(maxWidth: .infinity, alignment: .center)
//                        Text("© 2021 Kim Hansen").font(.footnote).foregroundColor(.gray)
                        Group {
                            Text("v. \(version) build \(build)")
                            Text("© 2021 Kim Hansen")
                            VStack {
                                Text("About to buy a new Tesla?")
                                Text("Use my referral code!")
                                Text("https://ts.la/kim85428")
                            }
                            
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(theme.backgroundColor2))
                            .cornerRadius(8)
                            .shadow(radius: theme.shadow)

                            
                            
                            
//                            .padding()
//                            .frame(maxWidth: .infinity)
//                            .modifier(LightBackground())
                            .onTapGesture {
                                #if os(iOS)
                                guard let writeReviewURL = URL(string: "https://ts.la/kim85428")
                                    else { fatalError("Expected a valid URL") }
                                UIApplication.shared.open(writeReviewURL, options: [:], completionHandler: nil)
                                #endif
                            }
                            }.font(.footnote).foregroundColor(.gray)

                    }
                }
                .padding([.top, .leading, .trailing])
                
                VStack (alignment: .leading, spacing: 16) {
                    Group {
                        Text("Friends of the app").bold()
                            .frame(maxWidth: .infinity)
                        
                        VStack {
                            ForEach(friends.shuffled(), id: \.name) { friend in
                                AppView(name: friend.name, appId: friend.appId, appUrl: friend.appUrl, icon: friend.icon)
                            }
                        }
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color(theme.backgroundColor2))
//                        .cornerRadius(8)
//                        .shadow(radius: theme.shadow)
                        //                        .appStoreOverlay(isPresented: $showOverlay) {
                        //                            SKOverlay.AppConfiguration(appIdentifier: overlayAppID, position: .bottom)
                        //                        }
                    }
                }
                .padding()
                
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
                
            }
        }
        .navigationBarTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
