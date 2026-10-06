//
//  TokenEndpointResponseTests.swift
//  TeslaAuthKitTests
//
//  Sorting token-endpoint answers into token / refused / unavailable
//  (#48: HTTP errors used to count as success; #49: offline is not a
//  refusal).
//

import Testing
import Foundation
@testable import TeslaAuthKit

@Suite("Token endpoint response classification")
struct TokenEndpointResponseTests {
    private func body(_ dictionary: [String: Any]) -> Data {
        try! JSONSerialization.data(withJSONObject: dictionary)
    }

    @Test("200 with every token field is a token")
    func success() throws {
        let now = Date(timeIntervalSince1970: 1_000)
        let response = TokenEndpointResponse.classify(
            statusCode: 200,
            body: body(["access_token": "a", "token_type": "Bearer", "expires_in": 28800, "refresh_token": "r2"]),
            transportError: nil, region: .china, now: now)
        guard case .token(let token) = response else { Issue.record("expected a token, got \(response)"); return }
        #expect(token.refresh_token == "r2")
        #expect(token.region == .china)
        #expect(token.expires_at == now.addingTimeInterval(28800))
    }

    @Test("400 invalid_grant is a refusal carrying Tesla's description")
    func invalidGrant() {
        let response = TokenEndpointResponse.classify(
            statusCode: 400, body: body(["error": "invalid_grant", "error_description": "The refresh_token is invalid"]),
            transportError: nil, region: .global)
        guard case .rejected(let reason) = response else { Issue.record("expected rejected, got \(response)"); return }
        #expect(reason == "The refresh_token is invalid")
    }

    @Test("401 with no body is a refusal")
    func unauthorized() {
        guard case .rejected = TokenEndpointResponse.classify(statusCode: 401, body: Data(), transportError: nil, region: .global) else {
            Issue.record("expected rejected"); return
        }
    }

    @Test("200 with login_required in the body is a refusal")
    func loginRequiredInBody() {
        guard case .rejected = TokenEndpointResponse.classify(statusCode: 200, body: body(["error": "login_required"]), transportError: nil, region: .global) else {
            Issue.record("expected rejected"); return
        }
    }

    @Test("A transport error is unavailable, never a refusal")
    func offline() {
        let error = URLError(.notConnectedToInternet)
        guard case .unavailable = TokenEndpointResponse.classify(statusCode: nil, body: Data(), transportError: error, region: .global) else {
            Issue.record("expected unavailable"); return
        }
    }

    @Test("5xx and 429 are unavailable")
    func serverErrors() {
        for status in [429, 500, 502, 503] {
            guard case .unavailable = TokenEndpointResponse.classify(statusCode: status, body: Data(), transportError: nil, region: .global) else {
                Issue.record("expected unavailable for \(status)"); return
            }
        }
    }

    @Test("200 missing fields is unavailable")
    func missingFields() {
        guard case .unavailable = TokenEndpointResponse.classify(statusCode: 200, body: body(["access_token": "a"]), transportError: nil, region: .global) else {
            Issue.record("expected unavailable"); return
        }
    }
}
