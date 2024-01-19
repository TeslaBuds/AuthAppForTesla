//
//  SetupViewSignIn.swift
//  AuthAppForTesla
//
//  Created by Nila on 20.02.21.
//

import SwiftUI
import CryptoKit

struct LoginViewSignIn: View {
    @ObservedObject var model: AuthViewModel
    let loginEnvironment: LoginEnvironment
    
    var body: some View {
        if loginEnvironment == .owner {
            LoginViewSignInOwnersAPI(model: model)
        } else {
            LoginViewSignInFleetAPI(model: model)
        }
    }
}

struct LoginViewSignIn_Previews: PreviewProvider {
    static var previews: some View {
        LoginViewSignIn(model: AuthViewModel(), loginEnvironment: .owner)
        LoginViewSignIn(model: AuthViewModel(), loginEnvironment: .fleet)
    }
}
