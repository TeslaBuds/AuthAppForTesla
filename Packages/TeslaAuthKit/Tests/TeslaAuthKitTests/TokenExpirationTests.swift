//
//  TokenExpirationTests.swift
//  Auth for Tesla Tests
//
//  #2: the expiration intents pick the right stored profile and report
//  its expiry, without touching storage.
//

import Foundation
import Testing
@testable import TeslaAuthKit

@Suite("Token expiration lookup")
struct TokenExpirationTests {

    private func token(expiresAt: Date?, accessToken: String = "not-a-jwt") -> Token {
        Token(
            access_token: accessToken,
            token_type: "bearer",
            expires_in: 28_800,
            refresh_token: "refresh",
            expires_at: expiresAt,
            region: .global
        )
    }

    @Test("No account picked: the active profile is used")
    func usesActiveProfile() {
        let first = TokenProfile(name: "First", token: token(expiresAt: .distantPast))
        let second = TokenProfile(name: "Second", token: token(expiresAt: .distantFuture))
        let collection = TokenProfileCollection(profiles: [first, second], activeProfileId: second.id)

        #expect(StoredTokenReader.profile(in: collection, id: nil)?.id == second.id)
    }

    @Test("A picked account is used, and an unknown one finds nothing")
    func usesPickedProfile() {
        let first = TokenProfile(name: "First", token: token(expiresAt: .distantPast))
        let second = TokenProfile(name: "Second", token: token(expiresAt: .distantFuture))
        let collection = TokenProfileCollection(profiles: [first, second], activeProfileId: second.id)

        #expect(StoredTokenReader.profile(in: collection, id: first.id)?.id == first.id)
        #expect(StoredTokenReader.profile(in: collection, id: UUID()) == nil)
        #expect(StoredTokenReader.profile(in: TokenProfileCollection(), id: nil) == nil)
    }

    @Test("The stored expiry is reported as is")
    func storedExpiry() {
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        #expect(StoredTokenReader.expirationDate(of: token(expiresAt: date)) == date)
    }

    @Test("A token stored without an expiry falls back to the access token's exp claim")
    func fallsBackToJWTClaim() {
        // {"alg":"none"} . {"exp":1800000000}
        let jwt = "eyJhbGciOiJub25lIn0.eyJleHAiOjE4MDAwMDAwMDB9.sig"
        let date = StoredTokenReader.expirationDate(of: token(expiresAt: nil, accessToken: jwt))
        #expect(date == Date(timeIntervalSince1970: 1_800_000_000))
        #expect(StoredTokenReader.expirationDate(of: token(expiresAt: nil)) == nil)
    }
}
