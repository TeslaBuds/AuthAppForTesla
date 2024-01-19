//
//  AuthAppForTeslaApp.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import SwiftUI

@main
struct AuthAppForTeslaApp: App {
    
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = UIColor(named: "NavigationBarColor")
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().tintColor = UIColor(named: "NavigationTitleColor")
#if !targetEnvironment(macCatalyst)
        if #available(iOS 15.0, *) {
            let tbapp = UITabBarAppearance()
            tbapp.backgroundColor = UIColor(named: "NavigationBarColor")
            UITabBar.appearance().scrollEdgeAppearance = tbapp
            UITabBar.appearance().standardAppearance = tbapp
        } else {
            // Fallback on earlier versions
        }
#endif
        
#if DEBUG
        if CommandLine.arguments.contains("enable-testing") {
            let token = Token(access_token: "", token_type: "bearer", expires_in: 0, refresh_token: "", expires_at: Date.distantPast, region: TokenRegion.global)
            AuthController.shared().setJwtToken(token)
        }
#endif
        
    }
    
    var body: some Scene {
        downloadLatestExternalApplicationList()
        return WindowGroup {
            let model = AuthViewModel()
            RootView(model: model)
                .navigationViewStyle(StackNavigationViewStyle())
//                .onOpenURL() { url in
//                    handleUniversalLink(url, model)
//                }
        }
    }
    
}
