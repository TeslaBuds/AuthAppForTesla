//
//  SetupView.swift
//  AuthAppForTesla
//
//  Created by Nila on 20.02.21.
//

import SwiftUI

struct LoginView: View {
    @ObservedObject var model: AuthViewModel
    @Environment(\.colorScheme) var colorScheme
    let loginEnvironment: LoginEnvironment
    
    var body: some View {
        IconBackgroundView{
            ScrollView {
                LoginViewHeader()
                Spacer()
                LoginViewFooter(model: model, loginEnvironment: loginEnvironment)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(model: AuthViewModel(), loginEnvironment: .fleet)
        LoginView(model: AuthViewModel(), loginEnvironment: .owner)
    }
}
