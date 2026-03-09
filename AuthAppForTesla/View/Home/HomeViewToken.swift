//
//  HomeViewToken.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI
import UniformTypeIdentifiers

enum TokenType {
    case accessToken
    case refreshToken
}

struct HomeViewToken: View {
    let title: String
    let description: String
    let token: Token?
    let tokenTypeToShow: TokenType
    let loginEnvironment: LoginEnvironment
    let showDetails: Bool

    @State private var fontSize: Double = 32
    @State private var checkOpacity: Double = 0

    private var tokenString: String? {
        tokenTypeToShow == .accessToken ? token?.access_token : token?.refresh_token
    }

    /// Copies the token string to the system clipboard with a 60-minute expiry
    /// so it is automatically cleared, reducing clipboard privacy exposure.
    private func copyTokenToClipboard() {
        guard let tokenString else { return }
        UIPasteboard.general.setItems(
            [[UTType.utf8PlainText.identifier: tokenString]],
            options: [.expirationDate: Date(timeIntervalSinceNow: 3600)]
        )
        animateCheck()
    }

    private func animateCheck() {
        fontSize = 16
        checkOpacity = 1

        withAnimation(.spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.3)) {
            fontSize = 60
        } completion: {
            withAnimation(.easeIn(duration: 0.2)) {
                checkOpacity = 0
            }
        }
    }
    
    var body: some View {
        ZStack {
            Button(action: copyTokenToClipboard) {
                VStack {
                    Text(title)
                        .font(.title2)
                        .bold()
                    Text(description)
                        .padding(.all, 1)
                        .multilineTextAlignment(.center)
                        .font(.subheadline)
                    if showDetails {
                        if tokenTypeToShow == .accessToken {
                            HomeViewAccessToken(token: token)
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Color("TeslaRed"))
                        } else {
                            HomeViewRefreshToken(token: token, loginEnvironment: loginEnvironment)
                                .font(.footnote)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(Color("TeslaRed"))
                        }
                    }
                    Text("Tap to copy to clipboard")
                        .padding(.all, 1)
                        .foregroundStyle(.secondary)
                        .font(.footnote)
                        .padding(.bottom, 5)
                }
            }
            .buttonStyle(.plain)
            
            Image(systemName: "checkmark.seal")
                .foregroundStyle(Color("TeslaRed"))
                .animatableFont(size: fontSize)
                .opacity(checkOpacity)
                .shadow(radius: 2)
        }
    }
}

#Preview {
    HomeViewToken(title: "Test", description: "Test description", token: nil, tokenTypeToShow: .accessToken, loginEnvironment: .fleet, showDetails: true)
}
