//
//  SheetDismissTests.swift
//  Auth for Tesla UI Tests
//
//  #69: the Add Account and Sign In Again sheets had a title-only Cancel.
//  On the iPhone Duo's outer display a sheet's bar is vertical, and the
//  system does not show a title-only item there — the sheet had no way
//  out. Both sheets now use one Cancel with an icon and the cancel role.
//  On the closed iPhone Duo simulator, run with
//  `TEST_RUNNER_DUO_OUTER_DISPLAY=1`, the test also checks that the bar
//  went vertical: Cancel sits below the title, not beside it. Before the
//  fix the title-only item kept the bar horizontal.
//
//  `enable-testing` seeds fixtures, so nothing reaches Tesla.
//

import XCTest

final class SheetDismissTests: XCTestCase {

    /// The closed iPhone Duo, whose sheets present their bar vertically.
    private static let duoOuterDisplay = ProcessInfo.processInfo.environment["DUO_OUTER_DISPLAY"] == "1"

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testAddAccountSheetCanBeCancelled() throws {
        let app = XCUIApplication()
        app.launchArguments = ["enable-testing", "screenshot-owners-home"]
        app.launch()
        defer { app.terminate() }

        let accountMenu = app.descendants(matching: .any)["homeMenu"].firstMatch
        XCTAssertTrue(accountMenu.waitForExistence(timeout: 10))
        accountMenu.tap()
        let addAccount = app.buttons["Add Another Account"].firstMatch
        XCTAssertTrue(addAccount.waitForExistence(timeout: 5))
        addAccount.tap()

        let title = app.staticTexts["Add Account"].firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 5), "the Add Account sheet did not open")

        let cancel = app.buttons["Cancel"].firstMatch
        XCTAssertTrue(cancel.waitForExistence(timeout: 5), "the sheet shows no Cancel")
        XCTAssertTrue(cancel.isHittable, "Cancel is not on screen")
        if Self.duoOuterDisplay {
            XCTAssertGreaterThan(cancel.frame.minY, title.frame.maxY,
                                 "the sheet's bar stayed horizontal on the Duo's outer display")
        }
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "add_account_sheet"
        shot.lifetime = .keepAlways
        add(shot)

        cancel.tap()
        let gone = expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: title)
        XCTAssertEqual(XCTWaiter.wait(for: [gone], timeout: 5), .completed, "Cancel did not close the sheet")
    }
}
