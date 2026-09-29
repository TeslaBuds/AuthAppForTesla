//
//  FriendLinkTests.swift
//  Auth for Tesla Tests
//

import Testing
import Foundation
@testable import AuthAppForTesla

/// #32 / #38: friend tiles open through `openURL`, never `SKStoreProductViewController`.
@Suite("FriendLink")
struct FriendLinkTests {

    @Test("App Store ID resolves to an apps.apple.com product URL")
    func appIdBecomesAppStoreURL() throws {
        let link = try #require(FriendLink(appId: "1532406445", appUrl: nil))
        #expect(link == .appStore(try #require(URL(string: "https://apps.apple.com/app/id1532406445"))))
    }

    @Test("App Store ID wins over a web URL")
    func appIdPreferredOverWebURL() throws {
        let link = try #require(FriendLink(appId: "6760581915", appUrl: "https://example.com"))
        guard case .appStore = link else {
            Issue.record("Expected an App Store link, got \(link)")
            return
        }
    }

    @Test("Web-only friend resolves to its web URL")
    func webURLOnly() throws {
        let link = try #require(FriendLink(appId: nil, appUrl: "https://teslascope.com"))
        #expect(link == .web(try #require(URL(string: "https://teslascope.com"))))
    }

    @Test("Scheme-less or missing links resolve to nothing")
    func invalidLinks() {
        #expect(FriendLink(appId: nil, appUrl: nil) == nil)
        #expect(FriendLink(appId: "", appUrl: "infinytum.co") == nil)
    }
}
