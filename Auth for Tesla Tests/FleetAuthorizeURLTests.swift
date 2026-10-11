//
//  FleetAuthorizeURLTests.swift
//  Auth for Tesla Tests
//
//  #53: the Fleet API authorize URL carries each value as one encoded
//  query item, whatever characters it contains.
//

import Testing
import Foundation
import TeslaAuthKit
@testable import AuthAppForTesla

@Suite("Fleet API authorize URL (#53)")
struct FleetAuthorizeURLTests {
    static func items(_ url: URL) throws -> [URLQueryItem] {
        try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
    }

    @Test("A redirect URI with its own query string stays one redirect_uri item",
          arguments: ["https://example.com/cb?app=tesla&x=1",
                      "https://example.com/o auth/callback#frag",
                      "https://exämple.com/callback?a=b+c",
                      "myapp://callback/path?prompt=none&state=evil"])
    func redirectUriIsOneItem(redirectUri: String) async throws {
        let request = try #require(await AuthController.shared.buildOAuthURLV4(
            region: .global, fleetClientId: "client-id", fleetRedirectUri: redirectUri))
        let items = try Self.items(request.url)

        #expect(items.filter { $0.name == "redirect_uri" }.map(\.value) == [redirectUri])
        #expect(items.filter { $0.name == "prompt" }.map(\.value) == ["login"])
        #expect(items.filter { $0.name == "state" }.map(\.value) == [request.state])
        #expect(items.filter { $0.name == "scope" }.map(\.value) == [AuthController.fleetScope])
        #expect(items.filter { $0.name == "response_type" }.map(\.value) == ["code"])
        #expect(items.count == 6)
        #expect(request.url.host() == "auth.tesla.com")
        #expect(request.url.path() == "/oauth2/v3/authorize")
    }

    @Test("A client ID with reserved characters arrives intact")
    func clientIdIsEncoded() async throws {
        let clientId = "abc&def=1+2 x"
        let request = try #require(await AuthController.shared.buildOAuthURLV4(
            region: .china, fleetClientId: clientId, fleetRedirectUri: "https://example.com/cb"))
        #expect(try Self.items(request.url).filter { $0.name == "client_id" }.map(\.value) == [clientId])
        #expect(request.url.host() == "auth.tesla.cn")
        #expect(!request.url.absoluteString.contains("abc&def"))
        #expect(!request.url.absoluteString.contains("1+2"))
    }

    @Test("Pasted credentials lose surrounding whitespace before use")
    func credentialsAreTrimmed() {
        let credentials = FleetCredentials(clientId: "  id\n", clientSecret: "\tsecret ", redirectUri: " https://example.com/cb\n")
        #expect(credentials.clientId == "id")
        #expect(credentials.clientSecret == "secret")
        #expect(credentials.redirectUri == "https://example.com/cb")
    }
}
