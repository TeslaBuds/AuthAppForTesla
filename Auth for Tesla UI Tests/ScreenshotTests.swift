//
//  ScreenshotTests.swift
//  Auth for Tesla UI Tests
//
//  Created by Kim Hansen on 08/03/2026.
//

import XCTest

/// Captures App Store screenshots in a single linear pass.
///
/// The app is launched once with the `enable-testing` flag, which injects
/// a realistic (but long-expired and harmless) JWT into the keychain.
/// This lets us capture both the authenticated and unauthenticated states
/// without any network calls.
///
/// Flow:
///  1. Owners API — authenticated home (token is present at launch)
///  2. Owners API — login screen (after tapping logout)
///  3. Fleet API — login screen (no Fleet token is ever set)
///  4. About
///
/// Each screenshot is saved as an `XCTAttachment` with `.keepAlways`
/// lifetime, which `xcparse` later extracts from the `.xcresult` bundle.
final class ScreenshotTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["enable-testing"]
    }

    @MainActor
    func testCaptureAllScreenshots() throws {
        app.launch()

        // ── 1. Owners API — Authenticated ──────────────────────────

        selectTab("Owners API")

        // Wait for the token to load and the home view to render.
        let refreshButton = app.buttons["refreshTokensButton"]
        XCTAssertTrue(
            refreshButton.waitForExistence(timeout: 10),
            "Expected authenticated Owners API home view"
        )

        takeScreenshot(named: "01_owners_home")

        // ── 2. Owners API — Login ──────────────────────────────────

        // Log out to reveal the login screen.
        let accountMenu = app.buttons["homeMenu"]
        XCTAssertTrue(accountMenu.waitForExistence(timeout: 5))
        accountMenu.tap()

        let logoutButton = app.buttons["logoutButton"]
        XCTAssertTrue(logoutButton.waitForExistence(timeout: 5))
        logoutButton.tap()

        // The login view should appear after logout.
        let loginButton = app.buttons["loginButton"]
        XCTAssertTrue(
            loginButton.waitForExistence(timeout: 5),
            "Expected Owners API login view after logout"
        )

        takeScreenshot(named: "02_owners_login")

        // ── 3. Fleet API — Login ───────────────────────────────────

        selectTab("Fleet API")
        sleep(1)

        takeScreenshot(named: "03_fleet_login")

        // ── 4. About ───────────────────────────────────────────────

        selectTab("About")
        sleep(1)

        takeScreenshot(named: "04_about")
    }

    // MARK: - Helpers

    /// Selects a tab by name, handling both iPhone (tab bar) and
    /// iPad (floating tab bar with duplicate accessibility elements).
    private func selectTab(_ name: String) {
        let button = app.buttons[name].firstMatch
        XCTAssertTrue(
            button.waitForExistence(timeout: 5),
            "Tab '\(name)' not found"
        )
        button.tap()
    }

    /// Captures a full-window screenshot and attaches it to the test
    /// result with a deterministic name for `xcparse` extraction.
    private func takeScreenshot(named name: String) {
        let screenshot = app.windows.firstMatch.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
