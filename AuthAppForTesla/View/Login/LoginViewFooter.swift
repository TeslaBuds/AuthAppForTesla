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
    
    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Spacer()
            Text("Login to Tesla to generate Tokens")
                .font(.title2)
            Text("In order to generate tokens, you have to login with your Tesla account.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.md)
            LoginViewSignIn(model: model, loginEnvironment: loginEnvironment)
                .padding(.vertical, AppSpacing.sm)
            Text("You will be presented with a web browser where you can enter your Tesla credentials into the Tesla website. If you have MFA configured you will be asked to enter a valid MFA code.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.lg)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(AppSpacing.cardInner)
        .glassEffect(.clear, in: .rect(cornerRadius: AppCornerRadius.container))
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
