//
//  HomeView.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI

struct OwnersAPIView: View {
    @ObservedObject var model: AuthViewModel
    
    var body: some View {
        if (model.tokenV3?.refresh_token.count ?? 0 == 0) ||
            (model.externalTokenRequest != nil)
        {
            LoginView(model: model, loginEnvironment: .owner)
        } else {
            HomeView(model: model, loginEnvironment: .owner)
        }
    }
}

struct OwnersAPIView_Previews: PreviewProvider {
    static var previews: some View {
        OwnersAPIView(model: AuthViewModel())
    }
}
