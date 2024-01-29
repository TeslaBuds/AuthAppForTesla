//
//  HomeViewToken.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI
import SwiftDate

struct HomeViewAccessToken: View {
    let token: Token?
    var body: some View {
        VStack{
            if let payload = token?.accessTokenPayload {
                if let ouCode = payload.ouCode {
                    Text("Region: ").foregroundColor(Color.primary)+Text(ouCode)
                }
                if let locale = payload.locale {
                    Text("Locale: ").foregroundColor(Color.primary)+Text(locale)
                }
                if let issuedAt = payload.issuedAtDate {
                    Text("Issued: ").foregroundColor(Color.primary)+Text(DateInRegion(issuedAt, region: Region.local).toString(DateToStringStyles.dateTimeMixed(dateStyle: .short, timeStyle: .short)))
                }
                if let expiresAt = payload.expiresAtDate {
                    Text("Expires: ").foregroundColor(Color.primary)+Text(DateInRegion(expiresAt, region: Region.local).toString(DateToStringStyles.dateTimeMixed(dateStyle: .short, timeStyle: .short)))
                }
                if let issuer = payload.issuer {
                    Text("Issuer: ").foregroundColor(Color.primary)+Text(issuer)
                }
                if let authorizedParty = payload.authorizedParty {
                    Text("Client ID: ").foregroundColor(Color.primary)+Text(authorizedParty)
                }
                if let audiences = payload.audiences {
                    Text("Audiences:").foregroundColor(Color.primary)
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
            }
        }
    }
}
