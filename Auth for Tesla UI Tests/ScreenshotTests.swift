//
//  ScreenshotTests.swift
//  Auth for Tesla UI Tests
//
//  Captures App Store screenshots — one test method per scenario.
//
//  Each test launches the app with `enable-testing` plus a scenario-
//  specific flag (e.g. `screenshot-jwt-inspector`). The app reads these
//  flags via `ScreenshotHarness` to seed token fixtures, choose the
//  initial tab, deep-link into a Tools sub-screen, and (where useful)
//  inject fake API results — all without ever hitting the network.
//
//  The screenshots are saved as `XCTAttachment`s with `.keepAlways`
//  lifetime so the shared DRSFramer capture script can extract them
//  from the .xcresult bundle.
//

import XCTest

final class ScreenshotTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // MARK: - Owners API

    @MainActor
    func testCapture01_OwnersHome() throws {
        let app = launch(scenario: "screenshot-owners-home")
        XCTAssertTrue(
            app.buttons["refreshTokensButton"].waitForExistence(timeout: 10),
            "Expected authenticated Owners API home view"
        )
        takeScreenshot(of: app, named: "01_owners_home")
    }

    @MainActor
    func testCapture02_OwnersLogin() throws {
        let app = launch(scenario: "screenshot-owners-login")
        XCTAssertTrue(
            app.buttons["loginButton"].waitForExistence(timeout: 10),
            "Expected Owners API login view"
        )
        takeScreenshot(of: app, named: "02_owners_login")
    }

    // MARK: - Tools

    @MainActor
    func testCapture03_TestToken() throws {
        let app = launch(scenario: "screenshot-test-token")
        // Wait for the navigation title to land on the Test Token screen.
        XCTAssertTrue(
            app.navigationBars["Test Token"].waitForExistence(timeout: 10),
            "Expected Test Token screen"
        )
        takeScreenshot(of: app, named: "03_test_token")
    }

    @MainActor
    func testCapture04_JWTInspector() throws {
        let app = launch(scenario: "screenshot-jwt-inspector")
        XCTAssertTrue(
            app.navigationBars["JWT Inspector"].waitForExistence(timeout: 10),
            "Expected JWT Inspector screen"
        )
        takeScreenshot(of: app, named: "04_jwt_inspector")
    }

    @MainActor
    func testCapture05_SnippetExporter() throws {
        let app = launch(scenario: "screenshot-snippet-exporter")
        XCTAssertTrue(
            app.navigationBars["Snippet Exporter"].waitForExistence(timeout: 10),
            "Expected Snippet Exporter screen"
        )
        takeScreenshot(of: app, named: "05_snippet_exporter")
    }

    // MARK: - Multi-account

    @MainActor
    func testCapture06_MultiAccount() throws {
        let app = launch(scenario: "screenshot-multi-account")
        XCTAssertTrue(
            app.buttons["refreshTokensButton"].waitForExistence(timeout: 10),
            "Expected authenticated Owners API home view"
        )
        // Open the account menu so the profile switcher is visible.
        let accountMenu = app.buttons["homeMenu"]
        XCTAssertTrue(accountMenu.waitForExistence(timeout: 5))
        accountMenu.tap()
        // Wait briefly for the menu to expand.
        sleep(1)
        takeScreenshot(of: app, named: "06_multi_account")
    }

    // MARK: - Fleet API

    @MainActor
    func testCapture07_FleetHome() throws {
        let app = launch(scenario: "screenshot-fleet-home")
        XCTAssertTrue(
            app.buttons["refreshTokensButton"].waitForExistence(timeout: 10),
            "Expected authenticated Fleet API home view"
        )
        takeScreenshot(of: app, named: "07_fleet_home")
    }

    // MARK: - About

    @MainActor
    func testCapture08_About() throws {
        let app = launch(scenario: "screenshot-about")
        sleep(1)
        takeScreenshot(of: app, named: "08_about")
    }

    // MARK: - Helpers

    private func launch(scenario: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["enable-testing", scenario]
        app.launch()
        return app
    }

    private func takeScreenshot(of app: XCUIApplication, named name: String) {
        let screenshot = app.windows.firstMatch.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
