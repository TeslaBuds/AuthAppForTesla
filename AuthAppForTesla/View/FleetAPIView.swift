//
//  HomeView.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI

struct FleetAPIView: View {
    @ObservedObject var model: AuthViewModel
    
    var body: some View {
        if (model.tokenV4?.refresh_token.count ?? 0 == 0)
        {
            LoginView(model: model, loginEnvironment: .fleet)
        } else {
            HomeView(model: model, loginEnvironment: .fleet)
        }
    }
}

struct FleetAPIView_Previews: PreviewProvider {
    static var previews: some View {
        FleetAPIView(model: AuthViewModel())
    }
}
