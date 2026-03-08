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
        VStack {
            if loginEnvironment == .owner {
                if let payload = token?.ownerRefreshTokenPayload {
                    if let issuedAt = payload.issuedAtDate {
                        let label = Text("Issued: ").foregroundStyle(.primary)
                        let value = Text(issuedAt.formatted(date: .abbreviated, time: .shortened))
                        Text("\(label)\(value)")
                    }
                    if let issuer = payload.issuer {
                        let label = Text("Issuer: ").foregroundStyle(.primary)
                        let value = Text(issuer)
                        Text("\(label)\(value)")
                    }
                    if let authorizedParty = payload.data?.authorizedParty {
                        let label = Text("Client ID: ").foregroundStyle(.primary)
                        let value = Text(authorizedParty)
                        Text("\(label)\(value)")
                    }
                    if let dataAudience = payload.data?.audience, let audience = payload.audience {
                        Text("Audiences:").foregroundStyle(.primary)
                        Text(audience)
                        Text(dataAudience)
                    }
                    if let scopes = payload.scopes {
                        Text("Scopes:").foregroundStyle(.primary)
                        ForEach(scopes, id: \.self) { scope in
                            Text(scope)
                        }
                    }
                }
            } else {
                if let payload = token?.fleetRefreshTokenPayload {
                    if let issuedAt = payload.issuedAtDate {
                        let label = Text("Issued: ").foregroundStyle(.primary)
                        let value = Text(issuedAt.formatted(date: .abbreviated, time: .shortened))
                        Text("\(label)\(value)")
                    }
                    if let issuer = payload.issuer {
                        let label = Text("Issuer: ").foregroundStyle(.primary)
                        let value = Text(issuer)
                        Text("\(label)\(value)")
                    }
                    if let authorizedParty = payload.data?.authorizedParty {
                        let label = Text("Client ID: ").foregroundStyle(.primary)
                        let value = Text(authorizedParty)
                        Text("\(label)\(value)")
                    }
                    if let audience = payload.audience, let audiences = payload.data?.audiences {
                        Text("Audiences:").foregroundStyle(.primary)
                        Text(audience)
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
                } else if let region = token?.fleetRefreshTokenRegion {
                    let label = Text("Region: ").foregroundStyle(.primary)
                    let value = Text(region)
                    Text("\(label)\(value)")
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
