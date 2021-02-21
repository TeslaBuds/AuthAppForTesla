//
//  HomeViewToken.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI

struct HomeViewToken: View {
    let action: () -> Void
    let title: String
    let description: String
    let token: String?
    
    init(title: String, description: String, token: String?, action: @escaping () -> Void) {
        self.action = action
        self.title = title
        self.description = description
        self.token = token
    }
    
    var body: some View {
        VStack{
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            Text(description)
                .padding(.all, 1)
                .multilineTextAlignment(.center)
                .font(.system(size: 15))
            Text("\(token ?? "")")
                .font(.system(size: 13))
                .multilineTextAlignment(.center)
                .foregroundColor(Color("TeslaRed"))
                .lineLimit(3)
                .onTapGesture {
                    let pasteBoard = UIPasteboard.general
                    pasteBoard.string = token
                    action()
                }
            Text("Tap to copy to clipboard")
                .padding(.all, 1)
                .foregroundColor(.gray)
                .font(.system(size: 13))
                .padding(.bottom, 5)
        }
    }
}

struct HomeViewToken_Previews: PreviewProvider {
    static var previews: some View {
        HomeViewToken(title: "Test", description: "Test description", token: "nope", action: {})
    }
}
