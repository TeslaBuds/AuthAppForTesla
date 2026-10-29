//
//  RetiredHandoffTests.swift
//  Auth for Tesla Tests
//
//  #56: every launch downloaded ExternalApplicationList.json for a token
//  hand-off nothing used, and the privacy manifest declared file-timestamp
//  access only to justify that cache. Kim chose removal (23 Oct 2026).
//

import Foundation
import Testing
@testable import AuthAppForTesla

@Suite("Retired token hand-off (#56)")
struct RetiredHandoffTests {
    /// The API categories the shipped privacy manifest declares.
    static func declaredAPICategories() throws -> [String] {
        let url = try #require(Bundle.main.url(forResource: "PrivacyInfo", withExtension: "xcprivacy"))
        let data = try Data(contentsOf: url)
        let plist = try #require(try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any])
        let types = try #require(plist["NSPrivacyAccessedAPITypes"] as? [[String: Any]])
        return types.compactMap { $0["NSPrivacyAccessedAPIType"] as? String }
    }

    @Test("The privacy manifest no longer declares file-timestamp access")
    func noFileTimestampReason() throws {
        #expect(!(try Self.declaredAPICategories()).contains("NSPrivacyAccessedAPICategoryFileTimestamp"))
    }

    @Test("No external application list ships in the app")
    func noBundledList() {
        #expect(Bundle.main.url(forResource: "ExternalApplicationList", withExtension: "json") == nil)
    }
}
