//
//  SnippetGenerator.swift
//  AuthAppForTesla
//
//  Generates copy-pasteable HTTP-client code for any bearer-token API call.
//  Used by the Snippet Exporter tool so developers can quickly try a Tesla
//  API endpoint in their language of choice.
//

import Foundation

enum SnippetLanguage: String, CaseIterable, Identifiable {
    case curl
    case httpie
    case swift
    case python

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .curl: "cURL"
        case .httpie: "HTTPie"
        case .swift: "Swift"
        case .python: "Python"
        }
    }
}

/// Static, pure helpers — easy to unit-test without touching SwiftUI.
enum SnippetGenerator {
    /// A reasonable default endpoint for each API surface, used as a
    /// placeholder when the user hasn't customised one.
    static func defaultEndpoint(for environment: LoginEnvironment, region: TokenRegion) -> String {
        switch environment {
        case .owner:
            switch region {
            case .global: return "https://owner-api.teslamotors.com/api/1/vehicles"
            case .china: return "https://owner-api.vn.cloud.tesla.cn/api/1/vehicles"
            }
        case .fleet:
            // Region prefix is detected from the refresh token at runtime;
            // fall back to a generic placeholder when nothing is known.
            return "https://fleet-api.prd.na.vn.cloud.tesla.com/api/1/users/me"
        }
    }

    static func snippet(language: SnippetLanguage, url: String, accessToken: String) -> String {
        switch language {
        case .curl:
            return curl(url: url, token: accessToken)
        case .httpie:
            return httpie(url: url, token: accessToken)
        case .swift:
            return swift(url: url, token: accessToken)
        case .python:
            return python(url: url, token: accessToken)
        }
    }

    private static func curl(url: String, token: String) -> String {
        """
        curl '\(url)' \\
          -H 'Authorization: Bearer \(token)' \\
          -H 'Accept: application/json'
        """
    }

    private static func httpie(url: String, token: String) -> String {
        """
        http GET '\(url)' \\
          'Authorization:Bearer \(token)' \\
          'Accept:application/json'
        """
    }

    private static func swift(url: String, token: String) -> String {
        """
        var request = URLRequest(url: URL(string: "\(url)")!)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        """
    }

    private static func python(url: String, token: String) -> String {
        """
        import requests

        response = requests.get(
            "\(url)",
            headers={
                "Authorization": "Bearer \(token)",
                "Accept": "application/json",
            },
        )
        response.raise_for_status()
        print(response.json())
        """
    }
}
