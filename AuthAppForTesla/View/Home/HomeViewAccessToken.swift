//
//  HomeViewAccessToken.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI

struct HomeViewAccessToken: View {
    let token: Token?

    var body: some View {
        if let payload = token?.accessTokenPayload {
            VStack(spacing: AppSpacing.xs) {
                if let ouCode = payload.ouCode {
                    TokenDetailRow(label: "Region", value: ouCode)
                }
                if let locale = payload.locale {
                    TokenDetailRow(label: "Locale", value: locale)
                }
                if let issuedAt = payload.issuedAtDate {
                    TokenDetailRow(label: "Issued", value: issuedAt.formatted(date: .abbreviated, time: .shortened))
                }
                if let expiresAt = payload.expiresAtDate {
                    TokenDetailRow(label: "Expires", value: expiresAt.formatted(date: .abbreviated, time: .shortened))
                }
                if let issuer = payload.issuer {
                    TokenDetailRow(label: "Issuer", value: issuer)
                }
                if let authorizedParty = payload.authorizedParty {
                    TokenDetailRow(label: "Client ID", value: authorizedParty)
                }
                if let audiences = payload.audiences, !audiences.isEmpty {
                    TokenDetailList(label: "Audiences", values: audiences)
                }
                if let scopes = payload.scopes, !scopes.isEmpty {
                    TokenDetailList(label: "Scopes", values: scopes)
                }
            }
        }
    }
}

#Preview("No Token") {
    HomeViewAccessToken(token: nil)
}

#Preview("With Token") {
    HomeViewAccessToken(token: Token(
        access_token: "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIn0",
        token_type: "bearer",
        expires_in: 3600,
        refresh_token: "refresh",
        expires_at: Date().addingTimeInterval(3600),
        region: .global
    ))
}
