//
//  HomeViewToken.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI
import SwiftDate

struct HomeViewRefreshToken: View {
    let token: Token?
    let loginEnvironment: LoginEnvironment
    
    var body: some View {
        VStack{
            if loginEnvironment == .owner {
                if let payload = token?.ownerRefreshTokenPayload {
                    if let issuedAt = payload.issuedAtDate {
                        Text("Issued: ").foregroundColor(Color.primary)+Text(DateInRegion(issuedAt, region: Region.local).toString(DateToStringStyles.dateTimeMixed(dateStyle: .short, timeStyle: .short)))
                    }
                    if let issuer = payload.issuer {
                        Text("Issuer: ").foregroundColor(Color.primary)+Text(issuer)
                    }
                    if let authorizedParty = payload.data?.authorizedParty {
                        Text("Client ID: ").foregroundColor(Color.primary)+Text(authorizedParty)
                    }
                    if let dataAudience = payload.data?.audience, let audience = payload.audience {
                        Text("Audiences:").foregroundColor(Color.primary)
                        Text(audience)
                        Text(dataAudience)
                    }
                    if let scopes = payload.scopes {
                        Text("Scopes:").foregroundColor(Color.primary)
                        ForEach(scopes, id: \.self) { scope in
                            Text(scope)
                        }
                    }
                }
            } else {
                if let payload = token?.fleetRefreshTokenPayload {
                    if let issuedAt = payload.issuedAtDate {
                        Text("Issued: ").foregroundColor(Color.primary)+Text(DateInRegion(issuedAt, region: Region.local).toString(DateToStringStyles.dateTimeMixed(dateStyle: .short, timeStyle: .short)))
                    }
                    if let issuer = payload.issuer {
                        Text("Issuer: ").foregroundColor(Color.primary)+Text(issuer)
                    }
                    if let authorizedParty = payload.data?.authorizedParty {
                        Text("Client ID: ").foregroundColor(Color.primary)+Text(authorizedParty)
                    }
                    if let audience = payload.audience, let audiences = payload.data?.audiences {
                        Text("Audiences:").foregroundColor(Color.primary)
                        Text(audience)
                        ForEach(audiences, id: \.self) { audience in
                            Text(audience)
                        }
                    }
                    if let scopes = payload.scopes {
                        Text("Scopes:").foregroundColor(Color.primary)
                        ForEach(scopes, id: \.self) { scope in
                            Text(scope)
                        }
                    }
                } else if let region = token?.fleetRefreshTokenRegion {
                    Text("Region: ").foregroundColor(Color.primary)+Text(region)
                }
            }
        }
    }
}
