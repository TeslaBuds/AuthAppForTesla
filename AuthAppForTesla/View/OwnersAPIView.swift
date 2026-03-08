//
//  OwnersAPIView.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI

struct OwnersAPIView: View {
    @Bindable var model: AuthViewModel
    
    var body: some View {
        if model.tokenV3?.refresh_token.count ?? 0 == 0 {
            LoginView(model: model, loginEnvironment: .owner)
        } else {
            HomeView(model: model, loginEnvironment: .owner)
        }
    }
}

#Preview {
    OwnersAPIView(model: AuthViewModel())
}
