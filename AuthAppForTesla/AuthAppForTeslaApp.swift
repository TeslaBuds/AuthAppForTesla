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
                        // Long-expired, harmless JWT that looks realistic
                        // in screenshots (token display, expiry label, etc.).
                        let sampleToken = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Ilg0RmNua0RCUVBUTnBrZTZiMnNuRi04YmdVUSJ9.eyJpc3MiOiJodHRwczovL2F1dGgudGVzbGEuY29tL29hdXRoMi92MyIsImF1ZCI6Imh0dHBzOi8vYXV0aC50ZXNsYS5jb20vb2F1dGgyL3YzL3Rva2VuIiwiaWF0IjoxNjM1NjgxODYwLCJzY3AiOlsib3BlbmlkIiwib2ZmbGluZV9hY2Nlc3MiXSwiZGF0YSI6eyJ2IjoiMSIsImF1ZCI6Imh0dHBzOi8vb3duZXItYXBpLnRlc2xhbW90b3JzLmNvbS8iLCJzdWIiOiIyMWZmMTg0MC0wMjU1LTQ0ODYtODU5Mi1lOGRlOTY1MWM1ZWUiLCJzY3AiOlsib3BlbmlkIiwiZW1haWwiLCJvZmZsaW5lX2FjY2VzcyJdLCJhenAiOiJvd25lcmFwaSIsImFtciI6WyJwd2QiXSwiYXV0aF90aW1lIjoxNjM1NjgxODYwfX0.NvyVC_8fkJmZLU0SWnAJJC8_k5jcHiNA54j0NYuAI15x3dTs2l8w27_uhdRsDbSWx8_YY0xcl8XTscxjhE4i7Ffc8S1Nn4rRsjgqkXZRlLFMn4A2vjnpzj-TlbMxlLHR0eIiE688nrJSkveoZ7h8_h9DB-wTgdmNUGR3tZkABRrefTHt4xGWL_HRX27cVV3worfdOiWlhBolDb_RrRzwzrFJjCz566liyJbChsfmfVExSDfFZHN7uDPp8V67HJKlvD1-aN-7ejUeAOjZz_isKBta5f1Zeq4QHOx9FyPH2YR5X3mUVRPp4yr3x8q_Nr8xNoB1DAkM2T2-G6yrcSmdjaoOvM2GV0RUSdl4j9KOTlWz8JqF-gczJJFeKEas1BwcPP2GL0jGpi_pD0L251Xcly9W0IUK_xpScBH1TbHDfBsu22tWdYoeQvpN2cG6krCdac-KuARLw4zOw2PWEQ3yjDftH0zD-2tWCpHxGYKJUany-_tooMC7kTtapIJnDk9DVoqU3f5raDLnVq_CfTcjfw3yUH2dY3YYqOLe-TWKt3pv0ae9IsD_XF5Y5vXYOP-7Oq5jK5I6R6j46dl1tm5S4yajQkWsTB3yDm667nth17OxEwhA8gzDKEBtagq79OT9hv14RGvLzVgiWrwNo8Rk0kz9NvPW_1mKdOJZRSHLhno"
                        let token = Token(
                            access_token: sampleToken,
                            token_type: "bearer",
                            expires_in: 28800,
                            refresh_token: sampleToken,
                            expires_at: .distantFuture,
                            region: .global
                        )
                        // Set both keychain and in-memory model directly
                        // to avoid race conditions during screenshot tests.
                        model.tokenV3 = token
                        await AuthController.shared.setJwtToken(token)
                        return
                    }
                    #endif
                    await model.loadTokens()
                    await downloadLatestExternalApplicationList()
                }
        }
    }
}
