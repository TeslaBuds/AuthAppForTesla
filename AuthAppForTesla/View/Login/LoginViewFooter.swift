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
            Text("Sign in to generate tokens")
                .font(.title2)
            Text("Sign in with your Tesla account to get a refresh token and an access token.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.md)
            LoginViewSignIn(model: model, loginEnvironment: loginEnvironment)
                .padding(.vertical, AppSpacing.sm)
            Text("You sign in on Tesla’s own website in a secure browser — your password never passes through this app. If you use MFA, you’ll be asked for your code there too.")
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
