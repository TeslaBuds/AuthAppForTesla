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
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
                        Text(title)
                            .font(.title3)
                            .bold()
                            .frame(maxWidth: .infinity, alignment: .leading)
                        TokenValidityBadge(
                            token: token,
                            tokenType: tokenTypeToShow
                        )
                    }
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    if showDetails {
                        Group {
                            if tokenTypeToShow == .accessToken {
                                HomeViewAccessToken(token: token)
                            } else {
                                HomeViewRefreshToken(token: token, loginEnvironment: loginEnvironment)
                            }
                        }
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Label("Tap to copy", systemImage: "doc.on.doc")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                .contentShape(.rect)
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

/// Inline status pill that lives next to a token's title. For the
/// access token it's a live "Valid for 1h 23m" countdown that flips
/// to "Expired" in TeslaRed when the deadline passes — replaces the
/// old "grey out the access token" mechanic, which incorrectly read
/// as "this token is the lesser of the two." For the refresh token
/// it's a quiet "Long-lived" reminder that the token isn't tied to a
/// short clock at all.
private struct TokenValidityBadge: View {
    let token: Token?
    let tokenType: TokenType

    var body: some View {
        switch tokenType {
        case .accessToken:
            accessBadge
        case .refreshToken:
            refreshBadge
        }
    }

    @ViewBuilder
    private var accessBadge: some View {
        if let expiresAt = token?.expires_at {
            let isExpired = expiresAt <= Date()
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: isExpired ? "xmark.octagon.fill" : "checkmark.seal.fill")
                if isExpired {
                    Text("Expired")
                } else {
                    // Relative countdown so the badge keeps ticking
                    // down as the user looks at it.
                    Text("Valid \(expiresAt, style: .relative)")
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(isExpired ? Color("TeslaRed") : .green)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .glassEffect(.regular, in: .capsule)
        }
    }

    @ViewBuilder
    private var refreshBadge: some View {
        if token != nil {
            HStack(spacing: AppSpacing.xs) {
                Image(systemName: "infinity")
                Text("Long-lived")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, AppSpacing.sm)
            .padding(.vertical, AppSpacing.xs)
            .glassEffect(.regular, in: .capsule)
        }
    }
}

#Preview("Access Token – Valid") {
    IconBackgroundView {
        HomeViewToken(
            title: "Access Token",
            description: "An access token allows for temporary access to your Tesla Account and typically expires after several hours.",
            token: Token(
                access_token: "eyJ…",
                token_type: "bearer",
                expires_in: 28_800,
                refresh_token: "r",
                expires_at: Date().addingTimeInterval(7_200),
                region: .global
            ),
            tokenTypeToShow: .accessToken,
            loginEnvironment: .owner,
            showDetails: false
        )
        .glassCard()
    }
}

#Preview("Access Token – Details") {
    IconBackgroundView {
        ScrollView {
            HomeViewToken(
                title: "Access Token",
                description: "An access token allows for temporary access to your Tesla Account and typically expires after several hours.",
                token: Token(
                    access_token: PreviewModelFactory.sampleAccessToken,
                    token_type: "bearer",
                    expires_in: 28_800,
                    refresh_token: PreviewModelFactory.sampleAccessToken,
                    expires_at: Date().addingTimeInterval(7_200),
                    region: .global
                ),
                tokenTypeToShow: .accessToken,
                loginEnvironment: .owner,
                showDetails: true
            )
            .glassCard()
        }
    }
}

#Preview("Refresh Token – Details") {
    IconBackgroundView {
        ScrollView {
            HomeViewToken(
                title: "Refresh Token (Recommended)",
                description: "A refresh token allows for continuous interaction with your Tesla Account and is usually what is requested by other apps and third-party services. This is used to generate new access tokens.",
                token: Token(
                    access_token: PreviewModelFactory.sampleAccessToken,
                    token_type: "bearer",
                    expires_in: 28_800,
                    refresh_token: PreviewModelFactory.sampleAccessToken,
                    expires_at: Date().addingTimeInterval(7_200),
                    region: .global
                ),
                tokenTypeToShow: .refreshToken,
                loginEnvironment: .owner,
                showDetails: true
            )
            .glassCard()
        }
    }
}

#Preview("Access Token – Expired") {
    IconBackgroundView {
        HomeViewToken(
            title: "Access Token",
            description: "An access token allows for temporary access to your Tesla Account and typically expires after several hours.",
            token: Token(
                access_token: "eyJ…",
                token_type: "bearer",
                expires_in: 28_800,
                refresh_token: "r",
                expires_at: Date().addingTimeInterval(-3_600),
                region: .global
            ),
            tokenTypeToShow: .accessToken,
            loginEnvironment: .owner,
            showDetails: false
        )
        .glassCard()
    }
}

#Preview("Refresh Token") {
    IconBackgroundView {
        HomeViewToken(
            title: "Refresh Token (Recommended)",
            description: "A refresh token allows for continuous interaction with your Tesla Account and is usually what is requested by other apps and third-party services. This is used to generate new access tokens.",
            token: Token(
                access_token: "a",
                token_type: "bearer",
                expires_in: 28_800,
                refresh_token: "eyJ…",
                expires_at: Date().addingTimeInterval(7_200),
                region: .global
            ),
            tokenTypeToShow: .refreshToken,
            loginEnvironment: .owner,
            showDetails: false
        )
        .glassCard()
    }
}
