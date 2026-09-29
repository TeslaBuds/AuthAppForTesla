//
//  TabNavigationTests.swift
//  Auth for Tesla UI Tests
//
//  #42: selecting a different tab must show it immediately, whatever was
//  pushed in the previous tab. A single NavigationStack around the TabView
//  left a pushed Tools screen covering every tab on Mac and iPad.
//

import XCTest

final class TabNavigationTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// A screen that can be pushed, and something only that screen shows.
    private struct Push {
        let tab: String
        let link: String
        let marker: (XCUIApplication) -> XCUIElement
        let name: String
    }

    private let pushes: [Push] = [
        Push(tab: "Tools", link: "Test Your Token", marker: { $0.navigationBars["Test Token"].firstMatch }, name: "testToken"),
        Push(tab: "Tools", link: "JWT Inspector", marker: { $0.navigationBars["JWT Inspector"].firstMatch }, name: "jwtInspector"),
        Push(tab: "Tools", link: "Snippet Exporter", marker: { $0.navigationBars["Snippet Exporter"].firstMatch }, name: "snippetExporter"),
        Push(tab: "About", link: "Open Source Licenses", marker: { $0.navigationBars["Open Source Licenses"].firstMatch }, name: "licenses"),
    ]

    private let tabs = ["Owners API", "Fleet API", "Tools", "About"]

    /// Something only the root of each tab shows.
    private func rootMarker(of tab: String, in app: XCUIApplication) -> XCUIElement {
        switch tab {
        case "Owners API":
            return app.descendants(matching: .any).matching(NSPredicate(format: "identifier IN %@", ["loginButton", "homeMenu"])).firstMatch
        case "Fleet API":
            return app.descendants(matching: .any).matching(NSPredicate(format: "identifier IN %@", ["loginButtonv4", "homeMenu"])).firstMatch
        case "Tools":
            return app.staticTexts["Diagnostic and developer tools that work with your stored Owners or Fleet API tokens."].firstMatch
        default:
            return app.staticTexts["More from Dansk Rumskrot"].firstMatch
        }
    }

    @MainActor
    func testSwitchingTabsShowsTheSelectedTabWhateverWasPushed() throws {
        let app = XCUIApplication()
        // Only skip onboarding. Never "live-test-clear-state": on Mac that
        // wipes the real (iCloud-synced) keychain profiles.
        app.launchArguments = ["-hasSeenOnboarding", "YES"]
        app.launch()

        for push in pushes {
            for target in tabs where target != push.tab {
                select(push.tab, in: app)
                // A tab keeps its own stack, so it may still show the
                // previous push; go back to its root first.
                popToRoot(in: app, until: rootMarker(of: push.tab, in: app))

                let link = app.descendants(matching: .any)[push.link].firstMatch
                XCTAssertTrue(link.waitForExistence(timeout: 5), "\(push.link) link missing")
                link.clickOrTap()
                XCTAssertTrue(push.marker(app).waitForExistence(timeout: 5), "\(push.name) did not open")
                attach(app, "\(push.name)_pushed_before_\(target)")

                select(target, in: app)
                // A tab keeps its own stack, so the target may show its root
                // or a screen pushed there earlier; either is that tab.
                let targetScreens = [rootMarker(of: target, in: app)]
                    + pushes.filter { $0.tab == target }.map { $0.marker(app) }
                XCTAssertTrue(
                    waitForAny(targetScreens),
                    "\(target) not shown after switching from \(push.tab) with \(push.name) pushed"
                )
                XCTAssertFalse(
                    push.marker(app).exists && push.marker(app).isHittable,
                    "\(push.name) still covers \(target)"
                )
                attach(app, "\(push.name)_then_\(target)")
            }
        }
    }

    private func waitForAny(_ elements: [XCUIElement], timeout: TimeInterval = 5) -> Bool {
        let deadline = Date.now.addingTimeInterval(timeout)
        repeat {
            if elements.contains(where: \.exists) { return true }
            usleep(250_000)
        } while Date.now < deadline
        return false
    }

    /// Taps the tab itself, never a same-named segment such as the
    /// Owners/Fleet picker on the Test Token screen.
    private func select(_ tab: String, in app: XCUIApplication) {
        let inTabBar = app.tabBars.buttons[tab].firstMatch
        let button = inTabBar.exists
            ? inTabBar
            : app.buttons.matching(NSPredicate(format: "label == %@", tab)).firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 5), "\(tab) tab missing")
        button.clickOrTap()
    }

    private func popToRoot(in app: XCUIApplication, until root: XCUIElement) {
        for _ in 0..<3 where !root.exists {
            let back = app.navigationBars.buttons.firstMatch
            guard back.exists else { return }
            back.clickOrTap()
            _ = root.waitForExistence(timeout: 2)
        }
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.windows.firstMatch.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
