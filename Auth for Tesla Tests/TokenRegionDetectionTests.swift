//
//  TokenRegionDetectionTests.swift
//  Auth for Tesla Tests
//

import Testing
import Foundation
@testable import AuthAppForTesla

@Suite("TokenRegionDetection")
struct TokenRegionDetectionTests {

    private func makeToken(refreshToken: String, region: TokenRegion?) -> Token {
        Token(
            access_token: "a",
            token_type: "bearer",
            expires_in: 3600,
            refresh_token: refreshToken,
            expires_at: nil,
            region: region
        )
    }

    @Test("Owner tokens fall back to global when no region stored")
    func ownerNoRegion() {
        let detected = makeToken(refreshToken: "anything", region: nil)
            .detectedRegion(for: .owner)
        #expect(detected.region == .global)
        #expect(detected.code == nil)
    }

    @Test("Owner tokens preserve the explicit china region")
    func ownerChina() {
        let detected = makeToken(refreshToken: "x", region: .china)
            .detectedRegion(for: .owner)
        #expect(detected.region == .china)
    }

    @Test("Fleet eu prefix maps to global with code")
    func fleetEUPrefix() {
        let detected = makeToken(refreshToken: "eu_some_long_refresh", region: nil)
            .detectedRegion(for: .fleet)
        #expect(detected.region == .global)
        #expect(detected.code == "eu")
        #expect(detected.displayName == "Europe")
    }

    @Test("Fleet cn prefix maps to china")
    func fleetCNPrefix() {
        let detected = makeToken(refreshToken: "cn_some_long_refresh", region: nil)
            .detectedRegion(for: .fleet)
        #expect(detected.region == .china)
        #expect(detected.code == "cn")
    }

    @Test("Explicit region wins over prefix detection")
    func explicitRegionWins() {
        let detected = makeToken(refreshToken: "eu_x", region: .china)
            .detectedRegion(for: .fleet)
        #expect(detected.region == .china)
        #expect(detected.code == "eu")
    }
}
