//
//  HomeViewToken.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI

enum TokenType {
    case accessToken
    case refreshToken
}

struct HomeViewToken: View {
    //    let action: () -> Void
    let title: String
    let description: String
    let token: Token?
    let tokenTypeToShow: TokenType
    let loginEnvironment: LoginEnvironment
    let showDetails: Bool
    
    @State private var fontSize: CGFloat = 32
    @State private var checkOpacity: Double = 0
    
    //    init(title: String, description: String, token: String?, action: @escaping () -> Void) {
    //        self.action = action
    //        self.title = title
    //        self.description = description
    //        self.token = token
    //    }
    
    fileprivate func animateCheck() {
        fontSize = 16
        checkOpacity = 1
        
        withAnimation(Animation.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.3)) {
            fontSize = 60
        }
        withAnimation(Animation.easeIn(duration: 0.2).delay(0.4)) {
            checkOpacity = 0
        }
    }
    
    var body: some View {
        ZStack{
            VStack{
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                Text(description)
                    .padding(.all, 1)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 15))
                if showDetails {
                    
                    if tokenTypeToShow == .accessToken {
                        HomeViewAccessToken(token: token)
                            .font(.system(size: 13))
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color("TeslaRed"))
                    } else {
                        HomeViewRefreshToken(token: token, loginEnvironment: loginEnvironment)
                            .font(.system(size: 13))
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color("TeslaRed"))
                    }
                }
                Text("Tap to copy to clipboard")
                    .padding(.all, 1)
                    .foregroundColor(.gray)
                    .font(.system(size: 13))
                    .padding(.bottom, 5)
            }
            .onTapGesture {
                let pasteBoard = UIPasteboard.general
                pasteBoard.string = tokenTypeToShow == .accessToken ? token?.access_token : token?.refresh_token
                animateCheck()
                //                action()
            }
            
            Group {
                Image(systemName: "checkmark.seal")
                    .foregroundColor(Color(UIColor(named: "TeslaRed")!))
                    .animatableFont(size: fontSize)
                    .opacity(checkOpacity)
                    .shadow(radius: 2)
            }
        }
    }
}

struct HomeViewToken_Previews: PreviewProvider {
    static var previews: some View {
        HomeViewToken(title: "Test", description: "Test description", token: nil, tokenTypeToShow: .accessToken, loginEnvironment: .fleet, showDetails: true)
    }
}
