//
//  SetupViewSignIn.swift
//  AuthAppForTesla
//
//  Created by Nila on 20.02.21.
//

import SwiftUI
import CryptoKit

struct LoginViewSignInOwnersAPI: View {
    @ObservedObject var model: AuthViewModel
    @State var region: TokenRegion = .global
    
    var body: some View {
        return VStack {
            
            
            Text("Choose login region")
            Picker("", selection: $region) {
                ForEach(TokenRegion.allCases) { region in
                    Text("\(NSLocalizedString(region.rawValue.capitalized, comment: ""))").tag(region)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.bottom, 10)
            Button("Sign in with Tesla", action: {
                model.logOut(environment: .owner)
                self.authenticateV3()
            })
                .accessibilityIdentifier("loginButton")
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .bottom)
                .padding(.vertical, 15)
                .foregroundColor(Color.white)
                .background(Color("TeslaRed"))
                .cornerRadius(10.0)
//                .disabled(model.externalTokenRequest != nil)
        }
        .padding(.horizontal, 35)
        .padding(.vertical, 20)
    }
    
    func authenticateV3() {
        DispatchQueue.main.async {
            if let vc = AuthController.shared.authenticateWeb(region: self.region, redirectUrl: kTeslaRedirectUri, completion: { (result) in
                switch result {
                case .success:
                    Task {
                        await model.acquireTokenSilentV3(forceRefresh: true)
                    }
                case .failure(let error):
                    print("Authenticate V3 error: \(error.localizedDescription)")
                }
            }) {
                UIApplication.topViewController?.present(vc, animated: true, completion: nil)
            }
        }
    }
}

struct LoginViewSignInOwnersAPI_Previews: PreviewProvider {
    static var previews: some View {
        LoginViewSignInOwnersAPI(model: AuthViewModel())
    }
}
