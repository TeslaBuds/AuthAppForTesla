//
//  TokenModels.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 27/01/2024.
//

import Foundation

public enum TokenRegion: String, Codable, CaseIterable, Identifiable {
    case global, china
    
    public var id: String { self.rawValue }
}

public struct Token: Codable {
    public let access_token: String
    public let token_type: String
    public let expires_in: Int
    public let refresh_token: String
    public var expires_at: Date?
    public var region: TokenRegion?

    public init(access_token: String, token_type: String, expires_in: Int, refresh_token: String, expires_at: Date? = nil, region: TokenRegion? = nil) {
        self.access_token = access_token
        self.token_type = token_type
        self.expires_in = expires_in
        self.refresh_token = refresh_token
        self.expires_at = expires_at
        self.region = region
    }
    
    public var accessTokenPayload: AccessToken? {
        let tokenParts = access_token.components(separatedBy: ".")
        guard tokenParts.count > 1,
              let decodedPayload = base64UrlDecode(tokenParts[1]),
              let accessToken = try? JSONDecoder().decode(AccessToken.self, from: decodedPayload)
        else {
            return nil
        }
        return accessToken
    }
    
    public var ownerRefreshTokenPayload: OwnerRefreshToken? {
        let tokenParts = refresh_token.components(separatedBy: ".")
        guard tokenParts.count > 1,
              let decodedPayload = base64UrlDecode(tokenParts[1]),
              let accessToken = try? JSONDecoder().decode(OwnerRefreshToken.self, from: decodedPayload)
        else {
            return nil
        }
        return accessToken
    }
    
    public var fleetRefreshTokenPayload: FleetRefreshToken? {
        let tokenParts = refresh_token.components(separatedBy: ".")
        guard tokenParts.count > 1,
              let decodedPayload = base64UrlDecode(tokenParts[1]),
              let accessToken = try? JSONDecoder().decode(FleetRefreshToken.self, from: decodedPayload)
        else {
            return nil
        }
        return accessToken
    }
    
    public var fleetRefreshTokenRegion: String? {
        if refresh_token.count > 3 {
            return String(refresh_token.prefix(2))
        }
        return nil
    }
}


public struct RequestEvent : Codable, Identifiable {
    public let id: Date
    public let when: Date
    public let message: String
}

public enum LoginEnvironment: String, Codable, CaseIterable, Identifiable {
    case owner
    case fleet
    public var id: String { self.rawValue }
}

// MARK: - Generic RefreshToken
public struct RefreshToken<T: Codable>: Codable {
    public let issuer: String?
    public let scopes: [String]?
    public let audience: String?
    public let subject: String?
    public let data: T?
    public let issuedAt: Int?
    
    public enum CodingKeys: String, CodingKey {
        case issuer = "iss"
        case scopes = "scp"
        case audience = "aud"
        case subject = "sub"
        case data = "data"
        case issuedAt = "iat"
    }
    
    public var issuedAtDate: Date? {
        if let issuedAt {
            return Date(timeIntervalSince1970: TimeInterval(issuedAt))// Date().addingTimeInterval(TimeInterval(issuedAt))
        }
        return nil
    }
}

// MARK: - FleetDataClass
public struct FleetDataClass: Codable {
    public let audiences: [String]?
    public let authorizedParty: String?
    
    public enum CodingKeys: String, CodingKey {
        case audiences = "aud"
        case authorizedParty = "azp"
    }
}

// MARK: - OwnerDataClass
public struct OwnerDataClass: Codable {
    public let audience: String?
    public let authorizedParty: String?
    
    public enum CodingKeys: String, CodingKey {
        case audience = "aud"
        case authorizedParty = "azp"
    }
}

public typealias FleetRefreshToken = RefreshToken<FleetDataClass>
public typealias OwnerRefreshToken = RefreshToken<OwnerDataClass>

// MARK: - AccessToken
public struct AccessToken: Codable {
    public let issuer: String?
    public let authorizedParty: String?
    public let subject: String?
    public let audiences: [String]?
    public let scopes: [String]?
    public let expiresAt: Int?
    public let issuedAt: Int?
    public let ouCode: String?
    public let locale: String?
    
    public enum CodingKeys: String, CodingKey {
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
    
    public var expiresAtDate: Date? {
        if let expiresAt {
            return Date(timeIntervalSince1970: TimeInterval(expiresAt))// Date().addingTimeInterval(TimeInterval(issuedAt))
        }
        return nil
    }
    
    public var issuedAtDate: Date? {
        if let issuedAt {
            return Date(timeIntervalSince1970: TimeInterval(issuedAt))// Date().addingTimeInterval(TimeInterval(issuedAt))
        }
        return nil
    }
}
