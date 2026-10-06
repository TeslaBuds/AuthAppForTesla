//
//  AuthControllerTests.swift
//  Auth for Tesla Tests
//
//  Created by Kim Hansen on 08/03/2026.
//

import Testing
import TeslaAuthKit
import Foundation
@testable import AuthAppForTesla

@Suite("AuthController")
struct AuthControllerTests {

    @Test("Build V3 OAuth URL contains required parameters")
    func buildOAuthURLV3ContainsRequiredParams() async {
        let result = await AuthController.shared.buildOAuthURLV3(
            region: .global,
            redirectUrl: "tesla://auth/callback"
        )

        let (url, codeVerifier, state) = try! #require(result)

        #expect(!codeVerifier.isEmpty)
        #expect(codeVerifier.count == 43)

        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let queryItems = components.queryItems ?? []
        let queryDict = Dictionary(
            queryItems.map { ($0.name, $0.value ?? "") },
            uniquingKeysWith: { first, _ in first }
        )

        #expect(components.host == "auth.tesla.com")
        #expect(components.path == "/oauth2/v3/authorize")
        #expect(queryDict["response_type"] == "code")
        #expect(queryDict["client_id"] == "ownerapi")
        #expect(queryDict["redirect_uri"] == "tesla://auth/callback")
        #expect(queryDict["scope"]?.contains("openid") == true)
        #expect(queryDict["code_challenge_method"] == "S256")
        #expect(queryDict["code_challenge"] != nil)
        #expect(queryDict["prompt"] == "login")
        // #51: the challenge is the verifier's, and state is random and sent.
        #expect(queryDict["code_challenge"] == codeVerifier.challenge)
        #expect(queryDict["state"] == state)
        #expect(state != "AuthAppForTesla")
    }

    @Test("Each V3 sign-in gets its own verifier and state (#51)")
    func buildOAuthURLV3IsRandomPerFlow() async throws {
        let first = try #require(await AuthController.shared.buildOAuthURLV3(region: .global, redirectUrl: "tesla://auth/callback"))
        let second = try #require(await AuthController.shared.buildOAuthURLV3(region: .global, redirectUrl: "tesla://auth/callback"))
        #expect(first.codeVerifier != second.codeVerifier)
        #expect(first.state != second.state)
    }

    @Test("Build V3 OAuth URL for China region")
    func buildOAuthURLV3China() async {
        let result = await AuthController.shared.buildOAuthURLV3(
            region: .china,
            redirectUrl: "tesla://auth/callback"
        )

        let (url, _, _) = try! #require(result)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        #expect(components.host == "auth.tesla.cn")
    }

    @Test("Build V4 (Fleet) OAuth URL contains required parameters")
    func buildOAuthURLV4ContainsRequiredParams() async {
        let request = await AuthController.shared.buildOAuthURLV4(
            region: .global,
            fleetClientId: "test-client-id",
            fleetRedirectUri: "https://example.com/callback"
        )

        let (safeURL, state) = try! #require(request)
        let components = URLComponents(url: safeURL, resolvingAgainstBaseURL: false)!
        let queryItems = components.queryItems ?? []
        let queryDict = Dictionary(
            queryItems.map { ($0.name, $0.value ?? "") },
            uniquingKeysWith: { first, _ in first }
        )

        #expect(components.host == "auth.tesla.com")
        #expect(components.path == "/oauth2/v3/authorize")
        #expect(queryDict["response_type"] == "code")
        #expect(queryDict["client_id"] == "test-client-id")
        #expect(queryDict["redirect_uri"] == "https://example.com/callback")
        #expect(queryDict["scope"]?.contains("vehicle_device_data") == true)
        #expect(queryDict["state"] == state)
        #expect(state.count >= 32)
    }

    @Test("Auth region URL mapping")
    func authRegionURL() async {
        let globalURL = await AuthController.shared.getAuthByRegion(region: .global)
        let chinaURL = await AuthController.shared.getAuthByRegion(region: .china)

        #expect(globalURL == "https://auth.tesla.com")
        #expect(chinaURL == "https://auth.tesla.cn")
    }
}
