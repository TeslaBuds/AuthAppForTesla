//
//  AuthAppForTeslaApp.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import SwiftUI

@main
struct AuthAppForTeslaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(model: AuthViewModel())
        }
    }
}
