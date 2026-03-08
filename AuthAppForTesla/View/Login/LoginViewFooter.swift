//
//  LoginViewFooter.swift
//  AuthAppForTesla
//
//  Created by Nila on 20.02.21.
//

import SwiftUI

struct LoginViewFooter: View {
    @Bindable var model: AuthViewModel
    let loginEnvironment: LoginEnvironment
    
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    
    var body: some View {
        VStack {
            Spacer()
            Text("Login to Tesla to generate Tokens")
                .font(.title2)
            Text("In order to generate tokens, you have to login with your Tesla account.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 25)
                .padding(.top, 2)
            LoginViewSignIn(model: model, loginEnvironment: loginEnvironment)
            Text("You will be presented with a web browser where you can enter your Tesla credentials into the Tesla website. If you have MFA configured you will be asked to enter a valid MFA code.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 35)
                .foregroundStyle(.secondary)
            Spacer()
            Text("v. \(version) build \(build)")
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding(.bottom)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding()
        .glassEffect(.clear, in: .rect(cornerRadius: 24))
        .padding()
    }
}

#Preview("Owner") {
    IconBackgroundView {
        LoginViewFooter(model: AuthViewModel(), loginEnvironment: .owner)
            .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview("Fleet") {
    LoginViewFooter(model: AuthViewModel(), loginEnvironment: .fleet)
}
