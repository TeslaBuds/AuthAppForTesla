//
//  LoginView.swift
//  AuthAppForTesla
//
//  Created by Nila on 20.02.21.
//

import SwiftUI

struct LoginView: View {
    @Bindable var model: AuthViewModel
    let loginEnvironment: LoginEnvironment
    
    var body: some View {
        IconBackgroundView {
            ScrollView {
                LoginViewHeader()
                Spacer()
                LoginViewFooter(model: model, loginEnvironment: loginEnvironment)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

#Preview("Fleet") {
    LoginView(model: AuthViewModel(), loginEnvironment: .fleet)
}

#Preview("Owner") {
    LoginView(model: AuthViewModel(), loginEnvironment: .owner)
}
