//
//  ScreenshotTests.swift
//  Auth for Tesla UI Tests
//
//  Captures App Store screenshots — one reel test, one launch per scenario.
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

    /// The whole App Store reel in one test (DRSFramer#26): eight one-shot
    /// methods paid the runner's per-test setup eight times for checks that
    /// only gate each capture. Every scenario still gets its own fresh launch
    /// and the same attachment name, so the capture script and `appstore.json`
    /// keys are unchanged.
    @MainActor
    func testCaptureReel() throws {
        // MARK: Owners API
        capture(scenario: "screenshot-owners-home", named: "01_owners_home") { app in
            XCTAssertTrue(
                app.buttons["refreshTokensButton"].waitForExistence(timeout: 10),
                "Expected authenticated Owners API home view"
            )
        }
        capture(scenario: "screenshot-owners-login", named: "02_owners_login") { app in
            XCTAssertTrue(
                app.buttons["loginButton"].waitForExistence(timeout: 10),
                "Expected Owners API login view"
            )
        }

        // MARK: Tools
        capture(scenario: "screenshot-test-token", named: "03_test_token") { app in
            XCTAssertTrue(
                app.navigationBars["Test Token"].waitForExistence(timeout: 10),
                "Expected Test Token screen"
            )
        }
        capture(scenario: "screenshot-jwt-inspector", named: "04_jwt_inspector") { app in
            XCTAssertTrue(
                app.navigationBars["JWT Inspector"].waitForExistence(timeout: 10),
                "Expected JWT Inspector screen"
            )
        }
        capture(scenario: "screenshot-snippet-exporter", named: "05_snippet_exporter") { app in
            XCTAssertTrue(
                app.navigationBars["Snippet Exporter"].waitForExistence(timeout: 10),
                "Expected Snippet Exporter screen"
            )
        }

        // MARK: Multi-account
        capture(scenario: "screenshot-multi-account", named: "06_multi_account") { app in
            XCTAssertTrue(
                app.buttons["refreshTokensButton"].waitForExistence(timeout: 10),
                "Expected authenticated Owners API home view"
            )
            // Open the account menu so the profile switcher is visible. On
            // Mac Catalyst the SwiftUI `Menu` is exposed as a popUpButton
            // rather than a button, so query by identifier across all types.
            let accountMenu = app.descendants(matching: .any)["homeMenu"].firstMatch
            XCTAssertTrue(accountMenu.waitForExistence(timeout: 5))
            accountMenu.tap()
            // Wait briefly for the menu to expand.
            sleep(1)
        }

        // MARK: Fleet API
        capture(scenario: "screenshot-fleet-home", named: "07_fleet_home") { app in
            XCTAssertTrue(
                app.buttons["refreshTokensButton"].waitForExistence(timeout: 10),
                "Expected authenticated Fleet API home view"
            )
        }

        // MARK: About
        capture(scenario: "screenshot-about", named: "08_about") { _ in
            sleep(1)
        }
    }

    // MARK: - Helpers

    /// Launches the app fresh into `scenario`, lets `ready` wait for (and
    /// gate) the screen, then attaches the window as `name`.
    @MainActor
    private func capture(
        scenario: String,
        named name: String,
        ready: (XCUIApplication) -> Void
    ) {
        XCTContext.runActivity(named: name) { _ in
            let app = XCUIApplication()
            app.launchArguments = ["enable-testing", scenario]
            app.launch()
            ready(app)
            let attachment = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
            attachment.name = name
            attachment.lifetime = .keepAlways
            add(attachment)
            app.terminate()
        }
    }
}
