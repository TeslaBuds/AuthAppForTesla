//
//  Auth_for_Tesla_UI_Tests.swift
//  Auth for Tesla UI Tests
//
//  Created by Kim Hansen on 08/03/2026.
//
//  This file is intentionally left minimal.
//  Screenshot capture tests live in ScreenshotTests.swift.
//

import XCTest

/// #32 / #38: tapping a cross-promoted app in the About tab must hand off
/// to the App Store via `openURL` instead of crashing, and on Mac both
/// cross-promotion sections must be present.
final class AboutFriendLinkTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAboutFriendTilesAreShownAndTappingOneDoesNotCrash() throws {
        let app = XCUIApplication()
        // Only skip onboarding. Never "live-test-clear-state" here: on Mac
        // that wipes the real (iCloud-synced) keychain profiles.
        app.launchArguments = ["-hasSeenOnboarding", "YES"]
        app.launch()

        let aboutTab = app.descendants(matching: .any)["About"].firstMatch
        XCTAssertTrue(aboutTab.waitForExistence(timeout: 10))
        aboutTab.clickOrTap()

        let moreHeading = app.staticTexts["More from Dansk Rumskrot"].firstMatch
        let friendsHeading = app.staticTexts["Friends of the App"].firstMatch
        let manaScope = app.buttons["ManaScope"].firstMatch
        for _ in 0..<8 where !(manaScope.exists && manaScope.isHittable) {
            #if targetEnvironment(macCatalyst)
            app.scrollViews.firstMatch.scroll(byDeltaX: 0, deltaY: -300)
            #else
            app.swipeUp()
            #endif
        }
        XCTAssertTrue(moreHeading.exists, "More from Dansk Rumskrot section missing")
        XCTAssertTrue(manaScope.waitForExistence(timeout: 5), "ManaScope tile missing")
        for _ in 0..<4 where !friendsHeading.exists {
            #if targetEnvironment(macCatalyst)
            app.scrollViews.firstMatch.scroll(byDeltaX: 0, deltaY: -300)
            #else
            app.swipeUp()
            #endif
        }
        XCTAssertTrue(friendsHeading.exists, "Friends of the App section missing")
        attach(app, "about_cross_promotion")

        manaScope.clickOrTap()
        sleep(4)
        let handoff = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        handoff.name = "after_tapping_ManaScope"
        handoff.lifetime = .keepAlways
        add(handoff)

        // The old SKStoreProductViewController path aborted the process.
        XCTAssertNotEqual(app.state, .notRunning, "App terminated after tapping a friend tile")
        app.activate()
        XCTAssertTrue(aboutTab.waitForExistence(timeout: 10), "App did not come back after the App Store hand-off")
        attach(app, "back_in_app")
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
