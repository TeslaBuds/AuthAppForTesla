//
//  HomeViewRefreshTokens.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI

struct HomeViewRefreshTokens: View {
    var model: AuthViewModel
    
    var body: some View {
        Button("Refresh Tokens") {
            model.refreshAll()
        }
        .buttonStyle(.glass(.regular.tint(Color("TeslaRed"))))
        .foregroundStyle(.white)
        .accessibilityIdentifier("refreshTokensButton")
    }
}

#Preview {
    HomeViewRefreshTokens(model: AuthViewModel())
}
