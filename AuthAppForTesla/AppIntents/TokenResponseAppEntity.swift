//
//  TokenResponseAppEntity.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 19/01/2024.
//

import Foundation
import AppIntents

struct TokenResponseAppEntity: TransientAppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Tesla Token")

    @Property(title: "Access Token")
    var accessToken: String

    @Property(title: "Refresh Token")
    var refreshToken: String

    @Property(title: "Expires At")
    var expiresAt: Date?

    @Property(title: "Region")
    var region: String?

    var displayRepresentation: DisplayRepresentation {
        let expiry = (expiresAt ?? .distantPast).formatted(date: .abbreviated, time: .shortened)
        return DisplayRepresentation(title: "\(region?.capitalized ?? "") Tesla Token, valid until: \(expiry)")
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
