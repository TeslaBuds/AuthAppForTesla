//
//  HomeViewRefreshTokens.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI
import TeslaAuthKit

struct HomeViewRefreshTokens: View {
    var model: AuthViewModel
    
    var body: some View {
        Button("Refresh Tokens") {
            model.refreshAll(.userRequest)
        }
        .buttonStyle(.glass(.regular.tint(Color("TeslaRed"))))
        .foregroundStyle(.white)
        .accessibilityIdentifier("refreshTokensButton")
    }
}

#Preview {
    HomeViewRefreshTokens(model: AuthViewModel())
}
