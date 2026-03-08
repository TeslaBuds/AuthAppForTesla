//
//  TokenModelTests.swift
//  Auth for Tesla Tests
//
//  Created by Kim Hansen on 08/03/2026.
//

import Testing
import Foundation
@testable import AuthAppForTesla

@Suite("Token Model")
struct TokenModelTests {

    @Test("Token encodes and decodes correctly")
    func tokenCodable() throws {
        let expiresAt = Date(timeIntervalSince1970: 1_700_000_000)
        let token = Token(
            access_token: "access-abc",
            token_type: "bearer",
            expires_in: 3600,
            refresh_token: "refresh-xyz",
            expires_at: expiresAt,
            region: .global
        )

        let data = try JSONEncoder().encode(token)
        let decoded = try JSONDecoder().decode(Token.self, from: data)

        #expect(decoded.access_token == "access-abc")
        #expect(decoded.token_type == "bearer")
        #expect(decoded.expires_in == 3600)
        #expect(decoded.refresh_token == "refresh-xyz")
        #expect(decoded.region == .global)
        #expect(decoded.expires_at == expiresAt)
    }

    @Test("Token with nil optional fields encodes and decodes")
    func tokenCodableNilOptionals() throws {
        let token = Token(
            access_token: "access",
            token_type: "bearer",
            expires_in: 7200,
            refresh_token: "refresh",
            expires_at: nil,
            region: nil
        )

        let data = try JSONEncoder().encode(token)
        let decoded = try JSONDecoder().decode(Token.self, from: data)

        #expect(decoded.expires_at == nil)
        #expect(decoded.region == nil)
    }

    @Test("TokenRegion raw values are correct")
    func tokenRegionRawValues() {
        #expect(TokenRegion.global.rawValue == "global")
        #expect(TokenRegion.china.rawValue == "china")
    }

    @Test("TokenRegion is identifiable")
    func tokenRegionIdentifiable() {
        #expect(TokenRegion.global.id == "global")
        #expect(TokenRegion.china.id == "china")
    }

    @Test("TokenRegion allCases contains both regions")
    func tokenRegionAllCases() {
        #expect(TokenRegion.allCases.count == 2)
        #expect(TokenRegion.allCases.contains(.global))
        #expect(TokenRegion.allCases.contains(.china))
    }

    @Test("LoginEnvironment raw values")
    func loginEnvironmentRawValues() {
        #expect(LoginEnvironment.owner.rawValue == "owner")
        #expect(LoginEnvironment.fleet.rawValue == "fleet")
    }

    @Test("Fleet refresh token region prefix extraction")
    func fleetRefreshTokenRegion() {
        let token = Token(
            access_token: "a",
            token_type: "bearer",
            expires_in: 0,
            refresh_token: "eu_some_long_token_data",
            expires_at: nil,
            region: nil
        )
        #expect(token.fleetRefreshTokenRegion == "eu")
    }

    @Test("Fleet refresh token region returns nil for short token")
    func fleetRefreshTokenRegionShort() {
        let token = Token(
            access_token: "a",
            token_type: "bearer",
            expires_in: 0,
            refresh_token: "ab",
            expires_at: nil,
            region: nil
        )
        #expect(token.fleetRefreshTokenRegion == nil)
    }
}
