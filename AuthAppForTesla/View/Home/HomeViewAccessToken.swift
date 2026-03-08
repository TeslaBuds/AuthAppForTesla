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
        VStack {
            if let payload = token?.accessTokenPayload {
                if let ouCode = payload.ouCode {
                    let label = Text("Region: ").foregroundStyle(.primary)
                    let value = Text(ouCode)
                    Text("\(label)\(value)")
                }
                if let locale = payload.locale {
                    let label = Text("Locale: ").foregroundStyle(.primary)
                    let value = Text(locale)
                    Text("\(label)\(value)")
                }
                if let issuedAt = payload.issuedAtDate {
                    let label = Text("Issued: ").foregroundStyle(.primary)
                    let value = Text(issuedAt.formatted(date: .abbreviated, time: .shortened))
                    Text("\(label)\(value)")
                }
                if let expiresAt = payload.expiresAtDate {
                    let label = Text("Expires: ").foregroundStyle(.primary)
                    let value = Text(expiresAt.formatted(date: .abbreviated, time: .shortened))
                    Text("\(label)\(value)")
                }
                if let issuer = payload.issuer {
                    let label = Text("Issuer: ").foregroundStyle(.primary)
                    let value = Text(issuer)
                    Text("\(label)\(value)")
                }
                if let authorizedParty = payload.authorizedParty {
                    let label = Text("Client ID: ").foregroundStyle(.primary)
                    let value = Text(authorizedParty)
                    Text("\(label)\(value)")
                }
                if let audiences = payload.audiences {
                    Text("Audiences:").foregroundStyle(.primary)
                    ForEach(audiences, id: \.self) { audience in
                        Text(audience)
                    }
                }
                if let scopes = payload.scopes {
                    Text("Scopes:").foregroundStyle(.primary)
                    ForEach(scopes, id: \.self) { scope in
                        Text(scope)
                    }
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
