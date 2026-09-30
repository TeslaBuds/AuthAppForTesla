//
//  AppIntentTrademarkTests.swift
//  Auth for Tesla Tests
//
//  Regression guard for ITMS-90626 ("Invalid Siri Support — App Intent
//  description cannot contain 'apple'"). App Store Connect rejects a
//  build whose App Intent metadata names an Apple device or service, and
//  the only notice is an email: the upload itself still "succeeds".
//  Copied from RumskrotSyndicate's test of the same name and extended to
//  read the App Intents metadata the build actually ships, so App
//  Shortcut phrases and parameter titles are covered too.
//

import AppIntents
import TeslaAuthKit
import Foundation
import Testing
@testable import AuthAppForTesla

@MainActor
@Suite("App Intent metadata carries no Apple trademarks")
struct AppIntentTrademarkTests {
    static let forbiddenWords = ["apple", "iphone", "ipad", "ipados", "mac", "macos", "siri", "watch"]

    /// One description per forbidden word found in `text`; empty when clean.
    static func violations(in text: String, source: String) -> [String] {
        forbiddenWords.compactMap { word in
            guard let regex = try? Regex("\\b\(word)\\b").ignoresCase(),
                  text.contains(regex) else { return nil }
            return "\(source) contains '\(word)': \"\(text)\""
        }
    }

    /// Checks one intent type's `title` and `description`.
    static func check(_ type: (some AppIntent).Type, into violations: inout [String]) {
        violations += Self.violations(in: String(localized: type.title), source: "\(type).title")
        if let description = type.description {
            violations += Self.violations(
                in: String(localized: description.descriptionText),
                source: "\(type).description"
            )
        }
    }

    @Test("The checker catches a trademark, word-bounded and case-insensitive")
    func checkerCatchesTrademarks() {
        #expect(!Self.violations(in: "Get the token on your iPhone", source: "t").isEmpty)
        #expect(!Self.violations(in: "Ask SIRI", source: "t").isEmpty)
        #expect(Self.violations(in: "Get the machine token", source: "t").isEmpty)
    }

    @Test("Titles and descriptions name no Apple device or service")
    func noTrademarksInIntentMetadata() {
        var violations: [String] = []

        Self.check(GetOwnersAPIToken.self, into: &violations)
        Self.check(GetFleetAPIToken.self, into: &violations)
        Self.check(RefreshOwnersAPIToken.self, into: &violations)
        Self.check(RefreshFleetAPIToken.self, into: &violations)
        Self.check(GetOwnersAPITokenExpiration.self, into: &violations)
        Self.check(GetFleetAPITokenExpiration.self, into: &violations)

        #expect(violations.isEmpty, "\(violations.joined(separator: "\n"))")
    }

    /// Every localizable string in the extracted App Intents metadata —
    /// the same file App Store Connect validates — including App Shortcut
    /// phrases, short titles and parameter titles.
    @Test("Shipped App Intents metadata, phrases included, names no Apple device or service")
    func noTrademarksInExtractedMetadata() throws {
        let url = try #require(
            Bundle.main.url(forResource: "extract", withExtension: "actionsdata", subdirectory: "Metadata.appintents"),
            "Metadata.appintents/extract.actionsdata missing from the app bundle"
        )
        let json = try JSONSerialization.jsonObject(with: Data(contentsOf: url))

        var strings: [String] = []
        Self.collectLocalizedKeys(in: json, into: &strings)
        #expect(strings.contains { $0.contains("Token Expiration") }, "Metadata does not list the expiration intents")

        let violations = strings.flatMap { Self.violations(in: $0, source: "extract.actionsdata") }
        #expect(violations.isEmpty, "\(violations.joined(separator: "\n"))")
    }

    /// Localized strings in the metadata are stored as `{"key": …}`.
    private static func collectLocalizedKeys(in value: Any, into strings: inout [String]) {
        if let dictionary = value as? [String: Any] {
            for (key, child) in dictionary {
                if key == "key", let string = child as? String {
                    strings.append(string)
                } else {
                    collectLocalizedKeys(in: child, into: &strings)
                }
            }
        } else if let array = value as? [Any] {
            for child in array { collectLocalizedKeys(in: child, into: &strings) }
        }
    }
}
