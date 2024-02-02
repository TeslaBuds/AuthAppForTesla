//
//  TokenModels.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 27/01/2024.
//

import Foundation

enum TokenRegion: String, Codable, CaseIterable, Identifiable {
    case global, china
    
    var id: String { self.rawValue }
}

struct Token: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int
    let refresh_token: String
    var expires_at: Date?
    var region: TokenRegion?
    //    let loginEnvironment: LoginEnvironment?
    
    var accessTokenPayload: AccessToken? {
        let tokenParts = access_token.components(separatedBy: ".")
        guard tokenParts.count > 1,
              let decodedPayload = base64UrlDecode(tokenParts[1]),
              let accessToken = try? JSONDecoder().decode(AccessToken.self, from: decodedPayload)
        else {
            return nil
        }
        return accessToken
    }
    
    var ownerRefreshTokenPayload: OwnerRefreshToken? {
        let tokenParts = refresh_token.components(separatedBy: ".")
        guard tokenParts.count > 1,
              let decodedPayload = base64UrlDecode(tokenParts[1]),
              let accessToken = try? JSONDecoder().decode(OwnerRefreshToken.self, from: decodedPayload)
        else {
            return nil
        }
        return accessToken
    }
    
    var fleetRefreshTokenPayload: FleetRefreshToken? {
        let tokenParts = refresh_token.components(separatedBy: ".")
        guard tokenParts.count > 1,
              let decodedPayload = base64UrlDecode(tokenParts[1]),
              let accessToken = try? JSONDecoder().decode(FleetRefreshToken.self, from: decodedPayload)
        else {
            return nil
        }
        return accessToken
    }
    
    var fleetRefreshTokenRegion: String? {
        if refresh_token.count > 3 {
            return String(refresh_token.prefix(2))
        }
        return nil
    }
}


struct RequestEvent : Codable, Identifiable {
    let id: Date
    let when: Date
    let message: String
}

enum LoginEnvironment: String, Codable, CaseIterable, Identifiable {
    case owner
    case fleet
    var id: String { self.rawValue }
}

// MARK: - Generic RefreshToken
struct RefreshToken<T: Codable>: Codable {
    let issuer: String?
    let scopes: [String]?
    let audience: String?
    let subject: String?
    let data: T?
    let issuedAt: Int?
    
    enum CodingKeys: String, CodingKey {
        case issuer = "iss"
        case scopes = "scp"
        case audience = "aud"
        case subject = "sub"
        case data = "data"
        case issuedAt = "iat"
    }
    
    var issuedAtDate: Date? {
        if let issuedAt {
            return Date(timeIntervalSince1970: TimeInterval(issuedAt))// Date().addingTimeInterval(TimeInterval(issuedAt))
        }
        return nil
    }
}

// MARK: - FleetDataClass
struct FleetDataClass: Codable {
    let audiences: [String]?
    let authorizedParty: String?
    
    enum CodingKeys: String, CodingKey {
        case audiences = "aud"
        case authorizedParty = "azp"
    }
}

// MARK: - OwnerDataClass
struct OwnerDataClass: Codable {
    let audience: String?
    let authorizedParty: String?
    
    enum CodingKeys: String, CodingKey {
        case audience = "aud"
        case authorizedParty = "azp"
    }
}

typealias FleetRefreshToken = RefreshToken<FleetDataClass>
typealias OwnerRefreshToken = RefreshToken<OwnerDataClass>

// MARK: - AccessToken
struct AccessToken: Codable {
    let issuer: String?
    let authorizedParty: String?
    let subject: String?
    let audiences: [String]?
    let scopes: [String]?
    let expiresAt: Int?
    let issuedAt: Int?
    let ouCode: String?
    let locale: String?
    
    enum CodingKeys: String, CodingKey {
        case issuer = "iss"
        case authorizedParty = "azp"
        case subject = "sub"
        case audiences = "aud"
        case scopes = "scp"
        case expiresAt = "exp"
        case issuedAt = "iat"
        case ouCode = "ou_code"
        case locale = "locale"
    }
    
    var expiresAtDate: Date? {
        if let expiresAt {
            return Date(timeIntervalSince1970: TimeInterval(expiresAt))// Date().addingTimeInterval(TimeInterval(issuedAt))
        }
        return nil
    }
    
    var issuedAtDate: Date? {
        if let issuedAt {
            return Date(timeIntervalSince1970: TimeInterval(issuedAt))// Date().addingTimeInterval(TimeInterval(issuedAt))
        }
        return nil
    }
}
