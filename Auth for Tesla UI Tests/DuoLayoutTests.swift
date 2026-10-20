//
//  DuoLayoutTests.swift
//  Auth for Tesla UI Tests
//
//  Every screen in portrait and in landscape, on whatever simulator runs
//  it — written for the iPhone Duo (TeslaBuds/AuthAppForTesla#66,
//  DRSFramer#72).
//
//  Each screen is launched once per orientation. The test checks that the
//  app follows the device into landscape (its window turns wide instead of
//  staying portrait-locked) and that the screen's primary control is on
//  screen and inside the window, then keeps a full-display screenshot of
//  both orientations as evidence.
//
//  Like ScreenshotTests, every launch passes `enable-testing`, so the app
//  shows seeded fixtures and never calls a Tesla API.
//

import XCTest

final class DuoLayoutTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = true
    }

    override func tearDownWithError() throws {
        XCUIDevice.shared.orientation = .portrait
    }

    /// A screen to check: its launch arguments and the element that must
    /// stay on screen in both orientations.
    private struct Screen {
        let name: String
        let arguments: [String]
        let anchor: (XCUIApplication) -> XCUIElement
    }

    private let screens: [Screen] = [
        Screen(name: "owners_home", arguments: ["screenshot-owners-home"]) { $0.buttons["refreshTokensButton"] },
        Screen(name: "owners_login", arguments: ["screenshot-owners-login"]) { $0.buttons["loginButton"] },
        Screen(name: "fleet_home", arguments: ["screenshot-fleet-home"]) { $0.buttons["refreshTokensButton"] },
        Screen(name: "tools", arguments: ["screenshot-tools"]) { $0.navigationBars.firstMatch },
        Screen(name: "jwt_inspector", arguments: ["screenshot-jwt-inspector"]) { $0.navigationBars["JWT Inspector"] },
        Screen(name: "snippet_exporter", arguments: ["screenshot-snippet-exporter"]) {
            $0.navigationBars["Snippet Exporter"]
        },
        Screen(name: "test_token", arguments: ["screenshot-test-token"]) { $0.navigationBars["Test Token"] },
        Screen(name: "about", arguments: ["screenshot-about"]) { $0.staticTexts["Auth for Tesla"].firstMatch },
        Screen(name: "onboarding", arguments: ["screenshot-onboarding"]) {
            $0.buttons["onboardingContinueButton"]
        },
        Screen(name: "toast", arguments: ["screenshot-owners-home", "show-toast"]) {
            $0.buttons["Dismiss"].firstMatch
        }
    ]

    @MainActor
    func testEveryScreenInBothOrientations() throws {
        for screen in screens {
            for orientation in [UIDeviceOrientation.portrait, .landscapeLeft] {
                check(screen, in: orientation)
            }
        }
    }

    // MARK: - Helpers

    /// Set (as `TEST_RUNNER_DISPLAY_CANNOT_ROTATE=1` on xcodebuild) for the
    /// iPhone Duo simulator in Xcode 27.1, whose closed outer display does
    /// not turn for `XCUIDevice.orientation` — even Settings stays
    /// 466×678 pt. The screenshots are still taken; the turn is checked on
    /// a simulator that can rotate.
    private static let displayCannotRotate = ProcessInfo.processInfo.environment["DISPLAY_CANNOT_ROTATE"] == "1"

    @MainActor
    private func check(_ screen: Screen, in orientation: UIDeviceOrientation) {
        let label = "\(screen.name)_\(orientation == .portrait ? "portrait" : "landscape")"
        XCUIDevice.shared.orientation = orientation
        let app = XCUIApplication()
        app.launchArguments = ["enable-testing"] + screen.arguments
        app.launch()
        defer { app.terminate() }

        let anchor = screen.anchor(app)
        XCTAssertTrue(anchor.waitForExistence(timeout: 10), "\(label): anchor missing")

        if orientation.isLandscape && !Self.displayCannotRotate {
            let window = app.windows.firstMatch
            let turned = expectation(for: NSPredicate { _, _ in
                window.frame.width > window.frame.height
            }, evaluatedWith: nil)
            let result = XCTWaiter.wait(for: [turned], timeout: 5)
            XCTAssertEqual(result, .completed, "\(label): the window stayed portrait in landscape")
        }
        capture(label)
        assertInsideWindow(anchor, of: app, label)
    }

    /// The anchor must be on screen, wholly inside the app's window. A
    /// control further down a scroll view may be scrolled to first.
    private func assertInsideWindow(_ element: XCUIElement, of app: XCUIApplication, _ label: String) {
        guard element.exists else { return }
        if !element.isHittable {
            app.swipeUp()
        }
        let window = app.windows.firstMatch.frame
        XCTAssertTrue(element.isHittable, "\(label): \(element) is not hittable")
        XCTAssertTrue(window.contains(element.frame), "\(label): \(element.frame) leaves the window \(window)")
    }

    /// The whole display, so a portrait lock or a letterbox shows up.
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
