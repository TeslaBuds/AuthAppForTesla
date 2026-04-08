//
//  TestAPIController.swift
//  AuthAppForTesla
//
//  Read-only diagnostic calls against the Tesla Owners and Fleet APIs.
//  Used by the "Test your token" tool. Nothing here is persisted —
//  results are summarised in-memory just so the user can see whether
//  their token actually works end to end.
//

import Foundation

/// A single test result row shown in the UI.
struct TestAPIResult: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let endpoint: String
    let status: Status
    let summary: String?

    enum Status: Equatable {
        case success
        case failure(statusCode: Int)
    }

    var isSuccess: Bool {
        if case .success = status { return true }
        return false
    }
}

actor TestAPIController {
    static let shared = TestAPIController()

    private init() {}

    // MARK: - Owners API (v3)

    func runOwnersAPITests(token: Token) async -> [TestAPIResult] {
        let baseURL = ownersBaseURL(region: token.region ?? .global)
        async let me = call(
            title: "GET /api/1/users/me",
            url: "\(baseURL)/api/1/users/me",
            token: token.access_token,
            summarize: { dict in
                if let response = dict["response"] as? [String: Any] {
                    let name = response["full_name"] as? String
                    let email = response["email"] as? String
                    return [name, email].compactMap { $0 }.joined(separator: " · ")
                }
                return nil
            }
        )
        async let vehicles = call(
            title: "GET /api/1/vehicles",
            url: "\(baseURL)/api/1/vehicles",
            token: token.access_token,
            summarize: { dict in
                if let count = dict["count"] as? Int {
                    return "\(count) vehicle\(count == 1 ? "" : "s")"
                }
                if let response = dict["response"] as? [Any] {
                    return "\(response.count) vehicle\(response.count == 1 ? "" : "s")"
                }
                return nil
            }
        )
        return await [me, vehicles]
    }

    private func ownersBaseURL(region: TokenRegion) -> String {
        switch region {
        case .global: "https://owner-api.teslamotors.com"
        case .china: "https://owner-api.vn.cloud.tesla.cn"
        }
    }

    // MARK: - Fleet API (v4)

    func runFleetAPITests(token: Token) async -> [TestAPIResult] {
        let baseURL = fleetBaseURL(token: token)
        async let me = call(
            title: "GET /api/1/users/me",
            url: "\(baseURL)/api/1/users/me",
            token: token.access_token,
            summarize: { dict in
                if let response = dict["response"] as? [String: Any] {
                    let name = response["full_name"] as? String
                    let email = response["email"] as? String
                    return [name, email].compactMap { $0 }.joined(separator: " · ")
                }
                return nil
            }
        )
        async let products = call(
            title: "GET /api/1/products",
            url: "\(baseURL)/api/1/products",
            token: token.access_token,
            summarize: { dict in
                if let count = dict["count"] as? Int {
                    return "\(count) product\(count == 1 ? "" : "s")"
                }
                if let response = dict["response"] as? [Any] {
                    return "\(response.count) product\(response.count == 1 ? "" : "s")"
                }
                return nil
            }
        )
        async let scopes = scopesResult(for: token)
        return await [me, products, scopes]
    }

    private func fleetBaseURL(token: Token) -> String {
        // Tesla encodes a 2-letter region prefix into Fleet refresh tokens
        // (eu, na, ap, me, cn). We use it to build the right host.
        let prefix = token.fleetRefreshTokenRegion?.lowercased() ?? "na"
        let isChina = prefix == "cn" || token.region == .china
        let suffix = isChina ? "cn" : "com"
        return "https://fleet-api.prd.\(prefix).vn.cloud.tesla.\(suffix)"
    }

    private func scopesResult(for token: Token) async -> TestAPIResult {
        let scopes = token.accessTokenPayload?.scopes ?? []
        if scopes.isEmpty {
            return TestAPIResult(
                title: "Token scopes",
                endpoint: "(decoded locally)",
                status: .failure(statusCode: 0),
                summary: "Token did not expose any scopes."
            )
        }
        return TestAPIResult(
            title: "Token scopes",
            endpoint: "(decoded locally)",
            status: .success,
            summary: scopes.joined(separator: ", ")
        )
    }

    // MARK: - Generic call

    private func call(
        title: String,
        url: String,
        token: String,
        summarize: @Sendable ([String: Any]) -> String?
    ) async -> TestAPIResult {
        let result = await NetworkController.shared.get(url, token: token)
        switch result {
        case .success(let response):
            let summary = summarize(response.dictionaryBody)
            return TestAPIResult(
                title: title,
                endpoint: url,
                status: .success,
                summary: summary
            )
        case .failure(let response):
            let summary = (response.dictionaryBody["error"] as? String)
                ?? (response.dictionaryBody["error_description"] as? String)
                ?? response.error.localizedDescription
            return TestAPIResult(
                title: title,
                endpoint: url,
                status: .failure(statusCode: response.statusCode),
                summary: summary
            )
        }
    }
}
