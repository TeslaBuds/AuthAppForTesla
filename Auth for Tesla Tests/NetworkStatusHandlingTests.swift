//
//  NetworkStatusHandlingTests.swift
//  Auth for Tesla Tests
//
//  #48: an HTTP error is a failure with its status and Tesla's
//  description, so Test Token fails a dead token and the refresh paths
//  see a refused refresh token as refused.
//

import Testing
import Foundation
import TeslaAuthKit
@testable import AuthAppForTesla

/// Answers every request with the status and body the test sets.
final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var status = 200
    nonisolated(unsafe) static var body = Data()
    nonisolated(unsafe) static var failWith: URLError?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        if let error = Self.failWith {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        let response = HTTPURLResponse(url: request.url!, statusCode: Self.status, httpVersion: "HTTP/1.1", headerFields: ["Content-Type": "application/json"])!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    static func network(status: Int, json: String, failWith: URLError? = nil) -> NetworkController {
        Self.status = status
        Self.body = Data(json.utf8)
        Self.failWith = failWith
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return NetworkController(configuration: configuration)
    }
}

@Suite("HTTP status handling (#48)", .serialized)
struct NetworkStatusHandlingTests {
    private static let token = Token(access_token: "dead", token_type: "bearer", expires_in: 3600, refresh_token: "r", expires_at: .now, region: .global)

    @Test("A 401 is a failure carrying the status and Tesla's description")
    func unauthorizedIsFailure() async {
        let network = StubURLProtocol.network(status: 401, json: #"{"error":"invalid_token","error_description":"token expired"}"#)
        let result = await network.get("https://owner-api.teslamotors.com/api/1/users/me", token: "dead")
        guard case .failure(let failure) = result else { Issue.record("a 401 was a success"); return }
        #expect(failure.statusCode == 401)
        #expect(failure.error.domain == "HTTP")
        #expect(failure.error.localizedDescription == "token expired")
        #expect(failure.dictionaryBody["error"] as? String == "invalid_token")
        #expect(!result.isTransportFailure)
    }

    @Test("A 200 is a success")
    func okIsSuccess() async {
        let network = StubURLProtocol.network(status: 200, json: #"{"response":{}}"#)
        guard case .success(let response) = await network.get("https://example.com") else { Issue.record("200 failed"); return }
        #expect(response.statusCode == 200)
    }

    @Test("A connection failure is a transport failure")
    func offlineIsTransportFailure() async {
        let network = StubURLProtocol.network(status: 200, json: "{}", failWith: URLError(.notConnectedToInternet))
        let result = await network.get("https://example.com")
        #expect(result.isTransportFailure)
    }

    @Test("Test Token fails both rows of a dead Owners token")
    func testTokenFailsDeadToken() async {
        let network = StubURLProtocol.network(status: 401, json: #"{"error":"invalid_token","error_description":"token expired"}"#)
        let rows = await TestAPIController(network: network).runOwnersAPITests(token: Self.token)
        #expect(rows.count == 2)
        for row in rows {
            #expect(row.status == .failure(statusCode: 401))
            #expect(row.summary == "token expired")
        }
    }

    @Test("A refused refresh is classified as refused, with Tesla's description")
    func refusedRefresh() async {
        let network = StubURLProtocol.network(status: 400, json: #"{"error":"invalid_grant","error_description":"The refresh_token is invalid"}"#)
        let result = await network.post("https://auth.tesla.com/oauth2/v3/token", parameters: ["grant_type": "refresh_token"])
        guard case .rejected(let reason) = TeslaTokenEndpoint.classify(result, region: .global) else {
            Issue.record("expected rejected"); return
        }
        #expect(reason == "The refresh_token is invalid")
    }

    @Test("An offline refresh is unavailable, not refused")
    func offlineRefresh() async {
        let network = StubURLProtocol.network(status: 200, json: "{}", failWith: URLError(.notConnectedToInternet))
        let result = await network.post("https://auth.tesla.com/oauth2/v3/token", parameters: [:])
        guard case .unavailable = TeslaTokenEndpoint.classify(result, region: .global) else {
            Issue.record("expected unavailable"); return
        }
    }
}
