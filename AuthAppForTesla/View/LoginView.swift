//
//  LoginView.swift
//  AuthAppForTesla
//
//  Created by Nila on 20.02.21.
//

import SwiftUI

struct LoginView: View {
    @Bindable var model: AuthViewModel
    @State private var scrollPosition = ScrollPosition()
    let loginEnvironment: LoginEnvironment
    
    var body: some View {
        IconBackgroundView {
            ScrollView {
                VStack(spacing: AppSpacing.cardGap) {
                    LoginViewHeader()
                    LoginViewFooter(model: model, loginEnvironment: loginEnvironment)
                        .fixedSize(horizontal: false, vertical: true)
                    TipJarView(scrollPosition: $scrollPosition)
                }
                .padding(.horizontal, AppSpacing.screenEdge)
                .padding(.top, AppSpacing.scrollTop)
                .padding(.bottom, AppSpacing.scrollBottom)
            }
            .scrollPosition($scrollPosition)
        }
    }
}

#Preview("Fleet") {
    LoginView(model: AuthViewModel(), loginEnvironment: .fleet)
}

#Preview("Owner") {
    LoginView(model: AuthViewModel(), loginEnvironment: .owner)
}
