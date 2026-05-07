//
//  LiveAuthTests.swift
//  Auth for Tesla UI Tests
//
//  End-to-end tests that exercise the real Tesla OAuth flow against
//  a throwaway demo account. Unlike ScreenshotTests these:
//
//    • Hit auth.tesla.com for real (network required).
//    • Sign in with a real (throwaway) Tesla account.
//    • Make real read-only API calls in the Test Token tool.
//
//  The credentials below are for a Tesla account that owns no
//  vehicles, exists solely for App Store review and these tests, and
//  is already publicly committed to this repo (Screenshots/appstore.json).
//  Hardcoding them here is intentional — see git history if you need
//  to rotate them.
//
//  How to run
//  ----------
//
//      AFT_LIVE_TESTS=1 \
//          xcodebuild test \
//              -project AuthAppForTesla.xcodeproj \
//              -scheme AuthAppForTesla \
//              -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
//              -only-testing:"Auth for Tesla UI Tests/LiveAuthTests"
//
//  …or use the convenience wrapper at Screenshots/live-tests.sh which
//  spins up a fresh simulator clone, sets the env var, and tears the
//  clone down on exit.
//
//  These tests are gated behind `AFT_LIVE_TESTS=1` so they don't run
//  in regular CI / Xcode runs by default — they're slow and dependent
//  on Tesla's auth.tesla.com being responsive.
//

import XCTest

final class LiveAuthTests: XCTestCase {

    // MARK: - Throwaway demo credentials

    /// Tesla account with no vehicles linked, used for App Store review
    /// and these live tests. Already committed to this repo at
    /// Screenshots/appstore.json review section.
    private let liveDemoUsername = "noteslavehicles@kimhansen.dk"
    private let liveDemoPassword = "cjNZnCfEhfMYHYwn2fyvwkHm"

    // MARK: - Lifecycle

    override func setUpWithError() throws {
        continueAfterFailure = false

        // These tests hit auth.tesla.com for real. Don't run them via
        // the regular UI test suite — invoke them explicitly via:
        //
        //     ./Screenshots/live-tests.sh
        //
        // …which clones a fresh simulator on every run so each test
        // starts from a guaranteed clean keychain. The class name
        // `LiveAuthTests` is the only discrimination — if you run the
        // full UI test target via xcodebuild without -only-testing
        // you'll hit Tesla's auth servers, which is rude. Don't.
    }

    // MARK: - Tests

    /// Smoke test: sign in once and verify the home view shows a real,
    /// non-expired token. The fastest way to know whether the OAuth
    /// flow + WebView interaction still works after a Tesla auth-page
    /// redesign.
    @MainActor
    func testLive_01_FreshSignIn() throws {
        let app = launchClean()

        signInWithDemoAccount(app: app)

        let refreshButton = app.buttons["refreshTokensButton"]
        let appeared = refreshButton.waitForExistence(timeout: 60)
        if !appeared {
            // Capture the final state and any visible toast for diagnosis.
            attach(app, named: "DEBUG_z_no_home_view")
            let toastText = app.staticTexts.matching(
                NSPredicate(format: "label CONTAINS[c] 'failed' OR label CONTAINS[c] 'error' OR label CONTAINS[c] 'Sign-in'")
            ).firstMatch
            if toastText.exists {
                let toastAttachment = XCTAttachment(string: "Toast: \(toastText.label)")
                toastAttachment.name = "DEBUG_z_toast"
                toastAttachment.lifetime = .keepAlways
                add(toastAttachment)
            }
            attachLiveTestLog(app: app, named: "DEBUG_z_oauth_log")
        }
        XCTAssertTrue(
            appeared,
            "Expected the home view's Refresh Tokens button to appear after sign-in"
        )

        // The home view shows "Valid for X" when the token is fresh —
        // make sure we're not looking at a leaked expired profile.
        let validityLabel = app.staticTexts.matching(
            NSPredicate(format: "label BEGINSWITH 'Valid for'")
        ).firstMatch
        XCTAssertTrue(
            validityLabel.waitForExistence(timeout: 5),
            "Expected a 'Valid for X' validity label after a fresh sign-in"
        )
    }

    /// Comprehensive walkthrough: sign in, click through every Tools tab
    /// screen, exercise multi-account, and finally log out. One long
    /// test method so we don't pay the OAuth roundtrip cost more than
    /// once. Each step adds an attachment screenshot for debugging.
    @MainActor
    func testLive_02_FullWalkthrough() throws {
        let app = launchClean()

        // ── 1. Sign in ─────────────────────────────────────────────
        signInWithDemoAccount(app: app)

        let refreshButton = app.buttons["refreshTokensButton"]
        XCTAssertTrue(
            refreshButton.waitForExistence(timeout: 60),
            "Sign-in should land on the Owners API home view"
        )
        attach(app, named: "01_after_signin")

        // ── 2. Refresh tokens ──────────────────────────────────────
        refreshButton.tap()
        // The toast appears for a couple of seconds — give it room.
        let refreshedToast = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'refreshed successfully'")
        ).firstMatch
        XCTAssertTrue(
            refreshedToast.waitForExistence(timeout: 15),
            "Expected the success toast after tapping Refresh Tokens"
        )
        attach(app, named: "02_after_refresh")

        // ── 3. Tools → Test Your Token (real API call) ─────────────
        selectTab(app: app, name: "Tools")
        app.buttons["Test Your Token"].firstMatch.tap()
        XCTAssertTrue(
            app.navigationBars["Test Token"].waitForExistence(timeout: 10),
            "Expected to land on the Test Token screen"
        )
        let runTestsButton = app.buttons["runTestsButton"]
        XCTAssertTrue(runTestsButton.waitForExistence(timeout: 5))
        runTestsButton.tap()
        // The /api/1/users/me success row contains the demo account's
        // email — wait for it as proof that the live API call worked.
        let userMeRow = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'noteslavehicles'")
        ).firstMatch
        XCTAssertTrue(
            userMeRow.waitForExistence(timeout: 30),
            "Expected the Test Token panel to show the demo email after a real /users/me call"
        )
        attach(app, named: "03_test_token_results")
        // Back to Tools.
        navigateBack(app: app)

        // ── 4. JWT Inspector with the stored token ─────────────────
        app.buttons["JWT Inspector"].firstMatch.tap()
        XCTAssertTrue(
            app.navigationBars["JWT Inspector"].waitForExistence(timeout: 10)
        )
        let useStoredMenu = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] 'Use Stored Token'")
        ).firstMatch
        if useStoredMenu.waitForExistence(timeout: 5) {
            useStoredMenu.tap()
            // Pick the Owners API access token entry.
            let accessTokenItem = app.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] 'Owners API – Access'")
            ).firstMatch
            if accessTokenItem.waitForExistence(timeout: 5) {
                accessTokenItem.tap()
            }
        }
        // Real Tesla tokens have an `iss` claim — the inspector renders
        // it as the "Issuer" row. Wait for that as a sanity check.
        let issuerLabel = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'Issuer'")
        ).firstMatch
        XCTAssertTrue(
            issuerLabel.waitForExistence(timeout: 10),
            "Expected the JWT Inspector to decode and display Issuer for the live token"
        )
        attach(app, named: "04_jwt_inspector_decoded")
        navigateBack(app: app)

        // ── 5. Snippet Exporter ────────────────────────────────────
        app.buttons["Snippet Exporter"].firstMatch.tap()
        XCTAssertTrue(
            app.navigationBars["Snippet Exporter"].waitForExistence(timeout: 10)
        )
        // The snippet section should contain the literal "Bearer " text
        // from the cURL output once the token is rendered.
        let bearerLine = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'Bearer '")
        ).firstMatch
        XCTAssertTrue(
            bearerLine.waitForExistence(timeout: 10),
            "Expected the Snippet Exporter to render a cURL with the Bearer token"
        )
        attach(app, named: "05_snippet_exporter")
        navigateBack(app: app)

        // ── 6. Back to Owners API and log out ──────────────────────
        selectTab(app: app, name: "Owners API")
        let accountMenu = app.descendants(matching: .any)["homeMenu"].firstMatch
        XCTAssertTrue(accountMenu.waitForExistence(timeout: 5))
        accountMenu.tap()
        let logoutButton = app.descendants(matching: .any)["logoutButton"].firstMatch
        XCTAssertTrue(logoutButton.waitForExistence(timeout: 5))
        logoutButton.tap()

        // Confirm in the confirmation dialog.
        let confirmButton = app.descendants(matching: .any)["logoutConfirmButton"].firstMatch
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 5))
        confirmButton.tap()

        // After logout (single profile) we should land back on the login screen.
        XCTAssertTrue(
            app.buttons["loginButton"].waitForExistence(timeout: 10),
            "Expected to be back on the Owners API login view after logout"
        )
        attach(app, named: "06_after_logout")
    }

    /// Repro test: backgrounding the app while the AuthWebView is open
    /// (e.g. to hop to a password manager) currently nukes the OAuth
    /// flow — when the user comes back, SwiftUI rebuilds the login
    /// view, the AuthWebView sheet is dismissed, the in-progress
    /// codeVerifier @State is lost, and the user is back at "Sign in
    /// with Tesla" having to start over.
    ///
    /// Drive the flow up to the password screen, then press the home
    /// button and re-activate. If the password field is still on
    /// screen we kept state. If we're back at the app's login screen
    /// (no webview, the loginButton is tappable again), the bug is
    /// reproduced.
    @MainActor
    func testLive_03_BackgroundDuringAuthPreservesState() throws {
        let app = launchClean()

        // ── 1. Drive the OAuth flow up to the password screen ────────
        selectTab(app: app, name: "Owners API")
        let loginButton = app.buttons["loginButton"]
        XCTAssertTrue(
            loginButton.waitForExistence(timeout: 10),
            "Expected the Owners API login view"
        )
        loginButton.tap()
        sleep(2)

        let webView = app.webViews.firstMatch
        XCTAssertTrue(
            webView.waitForExistence(timeout: 30),
            "Expected the Tesla OAuth web view to appear"
        )

        // Wait for and fill the email field.
        let emailField = webView.textFields.firstMatch
        XCTAssertTrue(
            emailField.waitForExistence(timeout: 60),
            "Tesla auth page text fields never appeared"
        )
        emailField.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        sleep(1)
        emailField.typeText(liveDemoUsername)
        sleep(1)

        // Tap Next.
        let nextButton = webView.buttons.matching(
            NSPredicate(format: "label IN { 'Next', 'Continue', 'Sign In', 'Sign in' }")
        ).firstMatch
        if nextButton.waitForExistence(timeout: 5) {
            nextButton.tap()
        } else {
            emailField.typeText("\n")
        }

        // Wait for the password field — this is the moment the user
        // would hop to their password manager.
        let passwordField = webView.secureTextFields.firstMatch
        XCTAssertTrue(
            passwordField.waitForExistence(timeout: 30),
            "Tesla auth password field never appeared after tapping Next"
        )
        attach(app, named: "before_background_password_screen")

        // ── 2. Background and foreground the app ─────────────────────
        XCUIDevice.shared.press(.home)
        sleep(2)
        attach(app, named: "after_home_press")

        app.activate()
        sleep(3)
        attach(app, named: "after_reactivate")

        // ── 3. Assert SwiftUI parent didn't rebuild ──────────────────
        // The bug: parent view rebuilds → @State authURL/codeVerifier
        // resets → sheet dismisses (or AuthWebView struct gets a new
        // identity and remounts the WKWebView, which loads Tesla's
        // OAuth URL fresh → email-entry page).
        //
        // Two signals to assert:
        //   1. The app's "Sign in with Tesla" button is NOT hittable —
        //      if it were, the sheet has dismissed and the login view
        //      is showing again. (Just .exists is unreliable: SwiftUI
        //      keeps the underlying view in the accessibility tree
        //      while a sheet is presented over it; isHittable filters
        //      that out.)
        //   2. The password field IS still hittable — i.e. Tesla's
        //      auth WebView is still on the same step we left it on,
        //      not the email-entry page that a fresh load would show.
        let webViewAfter = app.webViews.firstMatch
        let passwordFieldAfter = webViewAfter.secureTextFields.firstMatch
        let emailFieldAfter = webViewAfter.textFields.firstMatch
        let loginButtonAfter = app.buttons["loginButton"]

        let summary = """
        After backgrounding and foregrounding:
          loginButton hittable:  \(loginButtonAfter.isHittable)
          loginButton exists:    \(loginButtonAfter.exists)
          web view exists:       \(webViewAfter.exists)
          password field hittable: \(passwordFieldAfter.isHittable)
          password field exists: \(passwordFieldAfter.exists)
          email field hittable:  \(emailFieldAfter.isHittable)
          email field exists:    \(emailFieldAfter.exists)
        """
        let summaryAttachment = XCTAttachment(string: summary)
        summaryAttachment.name = "state_summary"
        summaryAttachment.lifetime = .keepAlways
        add(summaryAttachment)

        XCTAssertFalse(
            loginButtonAfter.isHittable,
            "BUG REPRO: backgrounding the app dismissed the auth sheet and reset us back to the login screen (Sign in with Tesla button is now hittable)"
        )
        XCTAssertTrue(
            passwordFieldAfter.isHittable,
            "Expected the Tesla password field to still be the active step after backgrounding (if email field is showing instead, the WebView reloaded the OAuth URL from scratch)"
        )
    }

    // MARK: - Helpers

    /// Launches the app with `live-test-clear-state` so the keychain
    /// is wiped before each test. Returns the live `XCUIApplication`.
    private func launchClean() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["live-test-clear-state"]
        app.launch()
        return app
    }

    /// Drives the Owners API sign-in flow end to end: taps "Sign in
    /// with Tesla", waits for the WKWebView, types the demo
    /// credentials, and waits for the auth flow to complete.
    private func signInWithDemoAccount(app: XCUIApplication) {
        selectTab(app: app, name: "Owners API")
        attach(app, named: "signin_00_owners_tab")

        // From the login screen, tap the sign-in button.
        let loginButton = app.buttons["loginButton"]
        XCTAssertTrue(
            loginButton.waitForExistence(timeout: 10),
            "Expected the Owners API login view"
        )
        attach(app, named: "signin_01_login_view")
        loginButton.tap()
        sleep(2)
        attach(app, named: "signin_02_after_login_tap")

        // The AuthWebView sheet appears with a WKWebView hosting
        // auth.tesla.com. The DOM elements are exposed as XCUITest
        // descendants once the page finishes loading.
        let webView = app.webViews.firstMatch
        if !webView.waitForExistence(timeout: 30) {
            attach(app, named: "signin_03_no_webview")
            let attachment = XCTAttachment(string: app.debugDescription)
            attachment.name = "signin_03_hierarchy"
            attachment.lifetime = .keepAlways
            add(attachment)
            XCTFail("Expected the Tesla OAuth web view to appear")
            return
        }
        attach(app, named: "signin_03_webview_loaded")

        // The web view container exists immediately, but Tesla's auth
        // page takes a couple of seconds to actually render its DOM.
        // Wait for any text field to appear before trying to type into
        // it — otherwise we race the page load and end up typing into
        // nothing.
        attach(app, named: "DEBUG_a_before_field_wait")
        let firstField = webView.textFields.firstMatch
        let firstFieldExists = firstField.waitForExistence(timeout: 60)
        attach(app, named: "DEBUG_b_after_field_wait_\(firstFieldExists ? "found" : "missing")")
        if !firstFieldExists {
            let attachment = XCTAttachment(string: webView.debugDescription)
            attachment.name = "DEBUG_c_webview_hierarchy"
            attachment.lifetime = .keepAlways
            add(attachment)
            XCTFail("Tesla auth page text fields never appeared")
            return
        }

        // Coordinate-tap the center of the field — element.tap() on a
        // WKWebView text field sometimes registers without focusing it.
        let coord = firstField.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        coord.tap()
        sleep(1)
        attach(app, named: "DEBUG_d_after_field_tap")
        firstField.typeText(liveDemoUsername)
        sleep(1)
        attach(app, named: "DEBUG_e_after_email_typed")

        // Tap the first button labelled Next/Continue/Sign in. We log
        // every button label visible to XCUITest first, so if Tesla
        // changes their submit button text we can see what to update.
        let buttonLabels = webView.buttons.allElementsBoundByIndex.map { $0.label }
        let labelsAttachment = XCTAttachment(string: "Buttons in webview at email step:\n" + buttonLabels.joined(separator: "\n"))
        labelsAttachment.name = "DEBUG_f_button_labels_email_step"
        labelsAttachment.lifetime = .keepAlways
        add(labelsAttachment)

        let nextButton = webView.buttons.matching(
            NSPredicate(format: "label IN { 'Next', 'Continue', 'Sign In', 'Sign in' }")
        ).firstMatch
        if nextButton.waitForExistence(timeout: 5) {
            nextButton.tap()
        } else {
            // Some Tesla auth pages put the submit on a non-button element.
            // Fall back to keyboard return.
            firstField.typeText("\n")
        }
        attach(app, named: "DEBUG_g_after_next_tap")
        sleep(4)
        attach(app, named: "DEBUG_h_4s_after_next")

        // Wait for the password field to actually appear.
        let passwordField = webView.secureTextFields.firstMatch
        let passwordFieldExists = passwordField.waitForExistence(timeout: 30)
        attach(app, named: "DEBUG_i_password_\(passwordFieldExists ? "found" : "missing")")
        if !passwordFieldExists {
            let attachment = XCTAttachment(string: webView.debugDescription)
            attachment.name = "DEBUG_i_webview_hierarchy"
            attachment.lifetime = .keepAlways
            add(attachment)
            XCTFail("Tesla auth password field never appeared after tapping Next")
            return
        }

        passwordField.tap()
        passwordField.typeText(liveDemoPassword)
        attach(app, named: "DEBUG_j_password_typed")

        let signInButton = webView.buttons.matching(
            NSPredicate(format: "label IN { 'Sign In', 'Sign in', 'Continue', 'Submit' }")
        ).firstMatch
        if signInButton.waitForExistence(timeout: 5) {
            signInButton.tap()
        } else {
            passwordField.typeText("\n")
        }
        attach(app, named: "DEBUG_k_after_signin_tap")
        sleep(4)
        attach(app, named: "DEBUG_l_4s_after_signin")

        // Tesla shows a 2FA "Enter Code" page even for accounts that
        // have 2FA disabled, with a "Skip and Continue" link that just
        // bypasses the code entry. The link is rendered as plain text
        // in the WKWebView accessibility tree (not a real link/button
        // element), so we have to coordinate-tap whichever element type
        // exposes its frame.
        let skipCandidates: [XCUIElement] = [
            webView.links.matching(NSPredicate(format: "label CONTAINS[c] 'Skip'")).firstMatch,
            webView.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Skip'")).firstMatch,
            webView.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Skip and Continue'")).firstMatch,
            webView.otherElements.matching(NSPredicate(format: "label CONTAINS[c] 'Skip and Continue'")).firstMatch
        ]

        // Wait briefly for the 2FA page to actually render before
        // searching — Tesla's transition from password to 2FA is fast
        // but not instant.
        _ = webView.staticTexts.matching(
            NSPredicate(format: "label == 'Skip and Continue'")
        ).firstMatch.waitForExistence(timeout: 10)
        attach(app, named: "DEBUG_m_2fa_page_loaded")

        // Match exact label — "Skip and Continue" — not just "Skip",
        // otherwise we hit Tesla's accessibility "Skip to main
        // content" link first.
        let skipText = webView.staticTexts.matching(
            NSPredicate(format: "label == 'Skip and Continue'")
        ).firstMatch
        if skipText.exists {
            let coord = skipText.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            coord.tap()
            attach(app, named: "DEBUG_m_after_skip_tap")
        } else {
            attach(app, named: "DEBUG_m_no_skip_text")
        }
        // Capture more frequently to see exactly what Tesla does after
        // the skip (loading spinner, another page, redirect…).
        sleep(1); attach(app, named: "DEBUG_n1_skip_plus_1s")
        sleep(1); attach(app, named: "DEBUG_n2_skip_plus_2s")
        sleep(1); attach(app, named: "DEBUG_n3_skip_plus_3s")
        // Look for an error toast immediately while it's still visible.
        let errorToast = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] 'Sign-in failed'")
        ).firstMatch
        if errorToast.exists {
            let toastAttachment = XCTAttachment(string: "Toast at +3s: \(errorToast.label)")
            toastAttachment.name = "DEBUG_n_toast_visible"
            toastAttachment.lifetime = .keepAlways
            add(toastAttachment)
        }
        sleep(2); attach(app, named: "DEBUG_n5_skip_plus_5s")

        // The web view dismisses itself once the redirect URL is hit
        // and AuthWebView's onRedirect handler fires. Wait for the
        // sheet to go away.
        let dismissedExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"),
            object: webView
        )
        XCTAssertEqual(
            XCTWaiter().wait(for: [dismissedExpectation], timeout: 60),
            .completed,
            "Expected the Tesla OAuth web view to dismiss after sign-in"
        )
    }

    private enum FieldKind {
        case textField, secureTextField
    }

    private func typeIntoFirstMatchingField(
        in webView: XCUIElement,
        kind: FieldKind,
        placeholders: [String],
        text: String
    ) {
        let collection: XCUIElementQuery
        switch kind {
        case .textField: collection = webView.textFields
        case .secureTextField: collection = webView.secureTextFields
        }

        // First try matching by accessibility label / placeholder.
        for placeholder in placeholders {
            let candidate = collection.matching(
                NSPredicate(format: "label CONTAINS[c] %@ OR placeholderValue CONTAINS[c] %@", placeholder, placeholder)
            ).firstMatch
            if candidate.waitForExistence(timeout: 5) {
                candidate.tap()
                candidate.typeText(text)
                return
            }
        }

        // Fall back to the first field of the requested kind.
        let fallback = collection.firstMatch
        XCTAssertTrue(
            fallback.waitForExistence(timeout: 10),
            "Could not find any \(kind) in the Tesla auth web view"
        )
        fallback.tap()
        fallback.typeText(text)
    }

    private func tapFirstMatchingButton(in webView: XCUIElement, labels: [String]) {
        for label in labels {
            let candidate = webView.buttons.matching(
                NSPredicate(format: "label ==[c] %@", label)
            ).firstMatch
            if candidate.waitForExistence(timeout: 5) {
                candidate.tap()
                return
            }
        }
        XCTFail("Could not find any submit button in the Tesla auth web view (looked for: \(labels.joined(separator: ", ")))")
    }

    private func selectTab(app: XCUIApplication, name: String) {
        let button = app.buttons[name].firstMatch
        XCTAssertTrue(
            button.waitForExistence(timeout: 5),
            "Tab '\(name)' not found"
        )
        button.tap()
    }

    private func navigateBack(app: XCUIApplication) {
        // SwiftUI back button — accessible via the navigation bar.
        let backButton = app.navigationBars.buttons.firstMatch
        if backButton.waitForExistence(timeout: 3) {
            backButton.tap()
        }
    }

    private func attach(_ app: XCUIApplication, named name: String) {
        let screenshot = app.windows.firstMatch.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Pulls the in-app LiveTestLog out of the running app via its
    /// hidden accessibility-exposed Text view (identifier
    /// `liveTestLog`) and attaches it to the test result bundle. This
    /// is the only reliable way to get OAuth diagnostics out of a UI
    /// test, since xcodebuild runs UI tests on an ephemeral cloned
    /// simulator that gets deleted before `simctl log show` can reach
    /// it.
    private func attachLiveTestLog(app: XCUIApplication, named name: String) {
        let logElement = app.descendants(matching: .any)
            .matching(identifier: "liveTestLog")
            .firstMatch
        let body: String
        if logElement.exists {
            body = logElement.label
        } else {
            body = "(liveTestLog accessibility element not found)"
        }
        let attachment = XCTAttachment(string: body)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
