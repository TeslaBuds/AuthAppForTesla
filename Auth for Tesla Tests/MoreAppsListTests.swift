//
//  MoreAppsListTests.swift
//  Auth for Tesla Tests
//

import Foundation
import Testing
import RumskrotAppsKit
@testable import AuthAppForTesla

/// #62: "More from Dansk Rumskrot" lists every live Dansk Rumskrot app from
/// RumskrotAppsKit's directory, with no curation, and never Auth itself.
@Suite("More from Dansk Rumskrot")
struct MoreAppsListTests {
    private let authBundleID = "dk.kimhansen.AuthAppForTesla"

    @Test("Lists exactly the directory's live siblings, in directory order")
    func listsEveryLiveSibling() {
        let shown = AboutViewMoreApps.apps(currentBundleID: authBundleID)
        let live = RumskrotApps.directory.filter { $0.appStoreID != nil && $0.bundleID != authBundleID }
        #expect(shown.map(\.id) == live.map(\.id))
    }

    @Test("Never lists Auth for Tesla itself")
    func excludesItself() {
        let shown = AboutViewMoreApps.apps(currentBundleID: authBundleID)
        #expect(!shown.contains { $0.kind == .authForTesla })
    }

    @Test("Includes the apps the old hand-written list was missing")
    func includesFormerlyMissingApps() {
        let kinds = Set(AboutViewMoreApps.apps(currentBundleID: authBundleID).map(\.kind))
        #expect(kinds.isSuperset(of: [.archives, .issues, .roadlens]))
    }

    @Test("Every listed app opens in the in-app store sheet")
    func everyAppHasAnAppStoreID() {
        for app in AboutViewMoreApps.apps(currentBundleID: authBundleID) {
            #expect(app.appStoreID?.isEmpty == false, "\(app.name) has no App Store ID")
        }
    }

    @Test("Auth has a public beta to invite testers to")
    func authHasABeta() throws {
        let program = try #require(BetaProgram(bundleID: authBundleID))
        #expect(program.testFlightURL.host() == "testflight.apple.com")
    }
}
