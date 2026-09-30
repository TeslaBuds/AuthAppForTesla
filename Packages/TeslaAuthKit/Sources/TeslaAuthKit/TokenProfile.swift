//
//  TokenProfile.swift
//  AuthAppForTesla
//
//  A named token profile, used so the user can keep multiple Tesla
//  Owners or Fleet API accounts side-by-side and switch between them.
//

import Foundation

public struct TokenProfile: Codable, Identifiable {
    public let id: UUID
    public var name: String
    public var token: Token

    public init(id: UUID = UUID(), name: String, token: Token) {
        self.id = id
        self.name = name
        self.token = token
    }
}

/// Persisted shape of the profile store. Holds multiple named profiles
/// per environment plus a pointer to whichever one the user has chosen
/// as the active profile.
public struct TokenProfileCollection: Codable {
    public var profiles: [TokenProfile]
    public var activeProfileId: UUID?

    public init(profiles: [TokenProfile] = [], activeProfileId: UUID? = nil) {
        self.profiles = profiles
        self.activeProfileId = activeProfileId
    }

    public var activeProfile: TokenProfile? {
        guard let activeProfileId else { return profiles.first }
        return profiles.first(where: { $0.id == activeProfileId }) ?? profiles.first
    }

    public mutating func upsert(_ profile: TokenProfile) {
        if let index = profiles.firstIndex(where: { $0.id == profile.id }) {
            profiles[index] = profile
        } else {
            profiles.append(profile)
        }
        if activeProfileId == nil {
            activeProfileId = profile.id
        }
    }

    public mutating func remove(id: UUID) {
        profiles.removeAll(where: { $0.id == id })
        if activeProfileId == id {
            activeProfileId = profiles.first?.id
        }
    }

    public mutating func rename(id: UUID, to name: String) {
        guard let index = profiles.firstIndex(where: { $0.id == id }) else { return }
        profiles[index].name = name
    }
}
