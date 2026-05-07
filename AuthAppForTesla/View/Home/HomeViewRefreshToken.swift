//
//  HomeViewRefreshToken.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI

struct HomeViewRefreshToken: View {
    let token: Token?
    let loginEnvironment: LoginEnvironment

    var body: some View {
        VStack(spacing: AppSpacing.xs) {
            if loginEnvironment == .owner {
                if let payload = token?.ownerRefreshTokenPayload {
                    if let issuedAt = payload.issuedAtDate {
                        TokenDetailRow(label: "Issued", value: issuedAt.formatted(date: .abbreviated, time: .shortened))
                    }
                    if let issuer = payload.issuer {
                        TokenDetailRow(label: "Issuer", value: issuer)
                    }
                    if let authorizedParty = payload.data?.authorizedParty {
                        TokenDetailRow(label: "Client ID", value: authorizedParty)
                    }
                    let audiences = [payload.audience, payload.data?.audience].compactMap { $0 }
                    if !audiences.isEmpty {
                        TokenDetailList(label: "Audiences", values: audiences)
                    }
                    if let scopes = payload.scopes, !scopes.isEmpty {
                        TokenDetailList(label: "Scopes", values: scopes)
                    }
                }
            } else {
                if let payload = token?.fleetRefreshTokenPayload {
                    if let issuedAt = payload.issuedAtDate {
                        TokenDetailRow(label: "Issued", value: issuedAt.formatted(date: .abbreviated, time: .shortened))
                    }
                    if let issuer = payload.issuer {
                        TokenDetailRow(label: "Issuer", value: issuer)
                    }
                    if let authorizedParty = payload.data?.authorizedParty {
                        TokenDetailRow(label: "Client ID", value: authorizedParty)
                    }
                    let audiences = ([payload.audience].compactMap { $0 }) + (payload.data?.audiences ?? [])
                    if !audiences.isEmpty {
                        TokenDetailList(label: "Audiences", values: audiences)
                    }
                    if let scopes = payload.scopes, !scopes.isEmpty {
                        TokenDetailList(label: "Scopes", values: scopes)
                    }
                } else if let region = token?.fleetRefreshTokenRegion {
                    TokenDetailRow(label: "Region", value: region)
                }
            }
        }
    }
}

#Preview("Owner - No Token") {
    HomeViewRefreshToken(token: nil, loginEnvironment: .owner)
}

#Preview("Fleet - No Token") {
    HomeViewRefreshToken(token: nil, loginEnvironment: .fleet)
}
