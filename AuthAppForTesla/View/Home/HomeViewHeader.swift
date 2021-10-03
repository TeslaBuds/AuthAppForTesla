//
//  HomeViewHeader.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI

struct HomeViewHeader: View {
    @ObservedObject var model: AuthViewModel
    
    var body: some View {
        HStack {
            VStack(alignment:. leading) {
                Text("Auth for Tesla")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Access Token valid for ").font(.subheadline) + Text(model.tokenV3?.expires_at ?? Date.distantPast, style: .relative)
                    .font(.subheadline)
                Text("Owners Token valid for ").font(.subheadline) + Text(model.tokenV2?.expires_at ?? Date.distantPast, style: .relative)
                    .font(.subheadline)
            }
            Spacer()
            Menu {
                Button("Logout", action: {
                    model.logOut()
                })
            } label: {
                Image(systemName: "person.crop.circle")
                    .foregroundColor(Color("TeslaRed"))
                    .font(.system(size: 30))
            }
        }
    }
}

struct HomeViewHeader_Previews: PreviewProvider {
    static var previews: some View {
        HomeViewHeader(model: AuthViewModel())
    }
}
