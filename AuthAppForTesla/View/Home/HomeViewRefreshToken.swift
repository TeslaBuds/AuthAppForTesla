//
//  HomeViewRefreshToken.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI

struct HomeViewRefreshToken: View {
    @ObservedObject var model: AuthViewModel
    
    var body: some View {
        Button(action: {
            model.refreshAll()
        }, label: {
            Text("Refresh Tokens")
                .font(.system(size: 18))
        })
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .bottom)
        .padding(.vertical, 15)
        .foregroundColor(Color.white)
        .background(Color("TeslaRed"))
        .cornerRadius(10.0)
    }
}

struct HomeViewRefreshToken_Previews: PreviewProvider {
    static var previews: some View {
        HomeViewRefreshToken(model: AuthViewModel())
    }
}
