//
//  AuthControllerTests.swift
//  Auth for Tesla Tests
//
//  Created by Kim Hansen on 08/03/2026.
//

import Testing
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

        let (url, codeVerifier) = try! #require(result)

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
    }

    @Test("Build V3 OAuth URL for China region")
    func buildOAuthURLV3China() async {
        let result = await AuthController.shared.buildOAuthURLV3(
            region: .china,
            redirectUrl: "tesla://auth/callback"
        )

        let (url, _) = try! #require(result)
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        #expect(components.host == "auth.tesla.cn")
    }

    @Test("Build V4 (Fleet) OAuth URL contains required parameters")
    func buildOAuthURLV4ContainsRequiredParams() async {
        let url = await AuthController.shared.buildOAuthURLV4(
            region: .global,
            fleetClientId: "test-client-id",
            fleetRedirectUri: "https://example.com/callback"
        )

        let safeURL = try! #require(url)
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
        #expect(queryDict["state"]?.hasPrefix("$STATE") == true)
    }

    @Test("Auth region URL mapping")
    func authRegionURL() async {
        let globalURL = await AuthController.shared.getAuthByRegion(region: .global)
        let chinaURL = await AuthController.shared.getAuthByRegion(region: .china)

        #expect(globalURL == "https://auth.tesla.com")
        #expect(chinaURL == "https://auth.tesla.cn")
    }
}
