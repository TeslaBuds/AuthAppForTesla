//
//  SnippetGeneratorTests.swift
//  Auth for Tesla Tests
//

import Testing
import Foundation
@testable import AuthAppForTesla

@Suite("SnippetGenerator")
struct SnippetGeneratorTests {

    private let url = "https://owner-api.teslamotors.com/api/1/vehicles"
    private let token = "abc.def.ghi"

    @Test("cURL snippet contains URL, bearer token, and Accept header")
    func curlSnippet() {
        let snippet = SnippetGenerator.snippet(language: .curl, url: url, accessToken: token)
        #expect(snippet.contains(url))
        #expect(snippet.contains("Bearer \(token)"))
        #expect(snippet.contains("Accept: application/json"))
        #expect(snippet.hasPrefix("curl"))
    }

    @Test("HTTPie snippet uses http command and bearer header")
    func httpieSnippet() {
        let snippet = SnippetGenerator.snippet(language: .httpie, url: url, accessToken: token)
        #expect(snippet.hasPrefix("http GET"))
        #expect(snippet.contains("Authorization:Bearer \(token)"))
    }

    @Test("Swift snippet uses URLRequest and async/await")
    func swiftSnippet() {
        let snippet = SnippetGenerator.snippet(language: .swift, url: url, accessToken: token)
        #expect(snippet.contains("URLRequest"))
        #expect(snippet.contains("Bearer \(token)"))
        #expect(snippet.contains("URLSession.shared.data"))
    }

    @Test("Python snippet uses requests library")
    func pythonSnippet() {
        let snippet = SnippetGenerator.snippet(language: .python, url: url, accessToken: token)
        #expect(snippet.contains("import requests"))
        #expect(snippet.contains("Bearer \(token)"))
        #expect(snippet.contains("response.raise_for_status()"))
    }

    @Test("Default endpoint differs by environment and region")
    func defaultEndpoint() {
        let owner = SnippetGenerator.defaultEndpoint(for: .owner, region: .global)
        #expect(owner.contains("owner-api.teslamotors.com"))

        let ownerCN = SnippetGenerator.defaultEndpoint(for: .owner, region: .china)
        #expect(ownerCN.contains("tesla.cn"))

        let fleet = SnippetGenerator.defaultEndpoint(for: .fleet, region: .global)
        #expect(fleet.contains("fleet-api"))
    }

    @Test("All snippet languages have a non-empty display name")
    func displayNames() {
        for lang in SnippetLanguage.allCases {
            #expect(!lang.displayName.isEmpty)
        }
    }
}
