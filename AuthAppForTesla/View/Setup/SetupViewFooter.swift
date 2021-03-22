//
//  SetupViewFooter.swift
//  AuthAppForTesla
//
//  Created by Nila on 20.02.21.
//

import SwiftUI

struct SetupViewFooter: View {
    @ObservedObject var model: AuthViewModel
    
    let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
    
    var body: some View {
        VStack{
            Spacer()
            Text("Login to Tesla to generate Tokens")
                .font(.system(size: 25, weight: .regular, design: .default))
            Text("In order to generate tokens, you have to login with your Tesla account.")
                .font(.system(size: 18, weight: .regular, design: .default))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 25)
                .padding(.top, 2)
            SetupViewSignIn(model: model)
            Text("You will be presented with a web browser where you can enter your Tesla credentials into the Tesla website. If you have MFA configured you will be asked to enter a valid MFA code.")
                .font(.system(size: 12, weight: .regular, design: .default))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 35)
                .foregroundColor(.gray)
            Spacer()
            Text("V. \(version) build \(build)")
                .font(.system(size: 12, weight: .regular, design: .default))
                .multilineTextAlignment(.center)
                .padding(.bottom, 15)
                .foregroundColor(.gray)
        }
        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .bottom)
        .background(Color("SheetColor").shadow(radius: 6))
    }
}

struct SetupViewFooter_Previews: PreviewProvider {
    static var previews: some View {
        SetupViewFooter(model: AuthViewModel())
    }
}
