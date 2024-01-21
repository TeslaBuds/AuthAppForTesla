//
//  TokenResponseAppEntity.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 19/01/2024.
//

import Foundation
import AppIntents
import SwiftDate

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct TokenResponseAppEntity: TransientAppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Tesla Token")
    
    @Property(title: "Access Token")
    var accessToken: String
    
    @Property(title: "Refresh Token")
    var refreshToken: String
    
    //@Property(title: "Expires At")
    //var expiresAt: DateComponents?
    
    @Property(title: "Expires At")
    var expiresAt: Date?
    
    @Property(title: "Region")
    var region: String?
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(region?.capitalized ?? "") Tesla Token, valid until: \(DateInRegion(expiresAt ?? Date.distantPast, region: Region.local).toString(DateToStringStyles.dateTimeMixed(dateStyle: .short, timeStyle: .short)))")
    }
    
    init() {
    }
    
    init(token: Token) {
        self.expiresAt = token.expires_at
        self.region = token.region?.rawValue
        self.accessToken = token.access_token
        self.refreshToken = token.refresh_token
    }
}
