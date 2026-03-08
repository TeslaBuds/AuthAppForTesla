//
//  LoginViewHeader.swift
//  AuthAppForTesla
//
//  Created by Nila on 20.02.21.
//

import SwiftUI

struct LoginViewHeader: View {
    var body: some View {
        VStack {
            Spacer()
            Image("SetupIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)
                .clipShape(.rect(cornerRadius: 10))
                .shadow(radius: 6)
            Text("Auth for Tesla")
                .font(.largeTitle)
                .bold()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    }
}

#Preview {
    LoginViewHeader()
}
