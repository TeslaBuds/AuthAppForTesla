//
//  LoginViewSignIn.swift
//  AuthAppForTesla
//
//  Created by Nila on 20.02.21.
//

import SwiftUI

struct LoginViewSignIn: View {
    @Bindable var model: AuthViewModel
    let loginEnvironment: LoginEnvironment
    
    var body: some View {
        if loginEnvironment == .owner {
            LoginViewSignInOwnersAPI(model: model)
        } else {
            LoginViewSignInFleetAPI(model: model)
        }
    }
}

#Preview("Owner") {
    LoginViewSignIn(model: AuthViewModel(), loginEnvironment: .owner)
}

#Preview("Fleet") {
    LoginViewSignIn(model: AuthViewModel(), loginEnvironment: .fleet)
}
