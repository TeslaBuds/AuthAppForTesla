//
//  MenuCommandTests.swift
//  Auth for Tesla UI Tests
//
//  #37: the menu bar commands (and the matching hardware-keyboard
//  shortcuts on iPad) must drive the app: ⌘1–⌘4 select the tabs, and
//  ⇧⌘C copies the token of the tab in front.
//

import XCTest

final class MenuCommandTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testKeyboardShortcutsSelectTabsAndCopyTheToken() throws {
        let app = XCUIApplication()
        // Seeded sample tokens, no network, no onboarding.
        app.launchArguments = ["enable-testing", "screenshot-owners-home"]
        app.launch()

        let ownersHome = app.descendants(matching: .any)["homeMenu"].firstMatch
        XCTAssertTrue(ownersHome.waitForExistence(timeout: 10), "Owners home not shown at launch")

        app.typeKey("3", modifierFlags: .command)
        XCTAssertTrue(
            app.staticTexts["Diagnostic and developer tools that work with your stored Owners or Fleet API tokens."]
                .firstMatch.waitForExistence(timeout: 5),
            "⌘3 did not select Tools"
        )
        attach(app, "cmd3_tools")

        app.typeKey("4", modifierFlags: .command)
        XCTAssertTrue(
            app.staticTexts["More from Dansk Rumskrot"].firstMatch.waitForExistence(timeout: 5),
            "⌘4 did not select About"
        )
        attach(app, "cmd4_about")

        app.typeKey("1", modifierFlags: .command)
        XCTAssertTrue(ownersHome.waitForExistence(timeout: 5), "⌘1 did not select Owners API")

        app.typeKey("c", modifierFlags: [.command, .shift])
        XCTAssertTrue(
            app.staticTexts["Access token copied."].firstMatch.waitForExistence(timeout: 5),
            "⇧⌘C did not copy the access token"
        )
        attach(app, "shift_cmd_c_copied")
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
