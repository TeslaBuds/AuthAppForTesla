//
//  TokenProfileTests.swift
//  Auth for Tesla Tests
//

import Testing
import Foundation
@testable import AuthAppForTesla

@Suite("TokenProfileCollection")
struct TokenProfileTests {

    private func makeProfile(name: String) -> TokenProfile {
        let token = Token(
            access_token: "a-\(name)",
            token_type: "bearer",
            expires_in: 3600,
            refresh_token: "r-\(name)",
            expires_at: nil,
            region: nil
        )
        return TokenProfile(name: name, token: token)
    }

    @Test("Upserting first profile activates it")
    func upsertActivates() {
        var collection = TokenProfileCollection()
        let profile = makeProfile(name: "Default")
        collection.upsert(profile)

        #expect(collection.profiles.count == 1)
        #expect(collection.activeProfileId == profile.id)
        #expect(collection.activeProfile?.id == profile.id)
    }

    @Test("Upserting an existing profile updates in place")
    func upsertUpdates() {
        var collection = TokenProfileCollection()
        var profile = makeProfile(name: "First")
        collection.upsert(profile)

        profile.name = "Renamed"
        collection.upsert(profile)

        #expect(collection.profiles.count == 1)
        #expect(collection.profiles.first?.name == "Renamed")
    }

    @Test("Removing the active profile reassigns active to first remaining")
    func removeReassignsActive() {
        var collection = TokenProfileCollection()
        let a = makeProfile(name: "A")
        let b = makeProfile(name: "B")
        collection.upsert(a)
        collection.upsert(b)
        #expect(collection.activeProfileId == a.id)

        collection.remove(id: a.id)

        #expect(collection.profiles.count == 1)
        #expect(collection.activeProfileId == b.id)
    }

    @Test("Renaming a profile updates its name")
    func rename() {
        var collection = TokenProfileCollection()
        let p = makeProfile(name: "Personal")
        collection.upsert(p)
        collection.rename(id: p.id, to: "Work")
        #expect(collection.profiles.first?.name == "Work")
    }

    @Test("Active profile falls back to first when explicit id is missing")
    func activeProfileFallback() {
        var collection = TokenProfileCollection()
        collection.upsert(makeProfile(name: "Only"))
        collection.activeProfileId = UUID() // points at nothing
        #expect(collection.activeProfile?.name == "Only")
    }

    @Test("Encodes and decodes round-trip")
    func codable() throws {
        var collection = TokenProfileCollection()
        collection.upsert(makeProfile(name: "Personal"))
        collection.upsert(makeProfile(name: "Work"))

        let data = try JSONEncoder().encode(collection)
        let decoded = try JSONDecoder().decode(TokenProfileCollection.self, from: data)

        #expect(decoded.profiles.count == 2)
        #expect(decoded.activeProfileId == collection.activeProfileId)
    }
}
