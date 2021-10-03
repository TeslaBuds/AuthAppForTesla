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
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView(model: AuthViewModel())
                .navigationViewStyle(StackNavigationViewStyle())
        }
    }
    
}
