//
//  AuthAppForTeslaApp.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import SwiftUI

@main
struct AuthAppForTeslaApp: App {
    @State private var model = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
                .task {
                    #if DEBUG
                    if CommandLine.arguments.contains("enable-testing") {
                        let token = Token(access_token: "", token_type: "bearer", expires_in: 0, refresh_token: "", expires_at: Date.distantPast, region: .global)
                        await AuthController.shared.setJwtToken(token)
                    }
                    #endif
                    await model.loadTokens()
                    await downloadLatestExternalApplicationList()
                }
        }
    }
}
