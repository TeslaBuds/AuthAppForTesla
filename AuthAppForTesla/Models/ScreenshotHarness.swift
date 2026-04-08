//
//  ScreenshotHarness.swift
//  AuthAppForTesla
//
//  Bridges screenshot launch arguments to in-memory state. The XCUITest
//  target launches the app with `enable-testing` plus a `screenshot-<key>`
//  flag, and this helper seeds whichever fixtures the matching screen
//  needs (single token, multi-profile, deep-linked Tools destination …).
//
//  CRITICAL: This harness must NEVER write to the keychain. The app's
//  KeychainWrapper is configured with `iCloudSync: true`, so any keychain
//  writes during a screenshot test would propagate to the user's real
//  iCloud Keychain and surface as bogus profiles in the live app on
//  every device they own. The harness instead pokes the in-memory
//  AuthViewModel directly, which is enough for SwiftUI to render the
//  populated state because the views read from the model, not from the
//  keychain.
//

import Foundation

/// Token fixtures used by the screenshot harness. These constants are
/// NOT gated by `#if DEBUG` because the production cleanup migration
/// needs to be able to recognise leaked fixture profiles in any build
/// configuration (users may have ended up with copies in their iCloud
/// Keychain from earlier 3.0.1 dev builds that did write to the
/// keychain — see ScreenshotFixtureCleanup).
enum ScreenshotFixtures {

    /// Long-expired but realistically-shaped Owners API JWT used in screenshots.
    /// Header: `{"alg":"RS256","typ":"JWT","kid":"X4FcnkDBQPTNpke6b2snF-8bgUQ"}`
    /// Payload: Owners API audience, realistic Tesla scopes, ou_code, locale,
    /// and an `exp` claim from 2025 so the JWT inspector renders a clear
    /// "Expired" status badge in the screenshot.
    static let sampleOwnersToken = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Ilg0RmNua0RCUVBUTnBrZTZiMnNuRi04YmdVUSJ9.eyJpc3MiOiJodHRwczovL2F1dGgudGVzbGEuY29tL29hdXRoMi92MyIsImF1ZCI6Imh0dHBzOi8vb3duZXItYXBpLnRlc2xhbW90b3JzLmNvbS8iLCJzdWIiOiIyMWZmMTg0MC0wMjU1LTQ0ODYtODU5Mi1lOGRlOTY1MWM1ZWUiLCJhenAiOiJvd25lcmFwaSIsInNjcCI6WyJvcGVuaWQiLCJlbWFpbCIsIm9mZmxpbmVfYWNjZXNzIiwidmVoaWNsZV9kZXZpY2VfZGF0YSIsInZlaGljbGVfY21kcyJdLCJpYXQiOjE3MzU2ODk2MDAsImV4cCI6MTczNTc3NjAwMCwib3VfY29kZSI6Ik5BIiwibG9jYWxlIjoiZW4tVVMifQ.signature"

    /// A second long-expired Owners JWT for a separate profile.
    static let sampleOwnersTokenWork = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJodHRwczovL2F1dGgudGVzbGEuY29tL29hdXRoMi92MyIsImF1ZCI6Imh0dHBzOi8vYXV0aC50ZXNsYS5jb20vb2F1dGgyL3YzL3Rva2VuIiwiaWF0IjoxNjM1NjgxODYwLCJzY3AiOlsib3BlbmlkIiwib2ZmbGluZV9hY2Nlc3MiXSwiZGF0YSI6eyJ2IjoiMSIsImF1ZCI6Imh0dHBzOi8vb3duZXItYXBpLnRlc2xhbW90b3JzLmNvbS8iLCJzdWIiOiI0NDU1ZTYwMC1iYjQ0LTQ4OWQtYjkxOC0wMzcyMDQzMDFmNDIiLCJzY3AiOlsib3BlbmlkIiwiZW1haWwiLCJvZmZsaW5lX2FjY2VzcyJdLCJhenAiOiJvd25lcmFwaSIsImFtciI6WyJwd2QiXSwiYXV0aF90aW1lIjoxNjM1NjgxODYwfX0.signature"

    /// Long-expired Fleet API JWT with realistic scopes (vehicle data, commands).
    static let sampleFleetToken = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJodHRwczovL2F1dGgudGVzbGEuY29tL29hdXRoMi92MyIsImF1ZCI6Imh0dHBzOi8vZmxlZXQtYXBpLnByZC5ldS52bi5jbG91ZC50ZXNsYS5jb20iLCJzdWIiOiJ1c2VyLWZsZWV0LTAxIiwiYXpwIjoiZXhhbXBsZS1jbGllbnQtaWQiLCJzY3AiOlsib3BlbmlkIiwib2ZmbGluZV9hY2Nlc3MiLCJ2ZWhpY2xlX2RldmljZV9kYXRhIiwidmVoaWNsZV9jbWRzIiwidmVoaWNsZV9jaGFyZ2luZ19jbWRzIl0sImlhdCI6MTczNTY4OTYwMCwiZXhwIjoxNzM1Nzc2MDAwLCJvdV9jb2RlIjoiRVUiLCJsb2NhbGUiOiJlbi1HQiJ9.signature"

    /// All fixture access tokens that the cleanup migration should
    /// recognise as leaked. Real Tesla tokens never end in `.signature`,
    /// so a hasSuffix check is also used as a belt-and-braces fallback.
    static let knownAccessTokens: Set<String> = [
        sampleOwnersToken,
        sampleOwnersTokenWork,
        sampleFleetToken
    ]

    /// True if the given token looks like one of our screenshot fixtures.
    /// Used by ScreenshotFixtureCleanup to wipe leaked profiles from the
    /// real keychain on app launch.
    static func isFixture(_ token: Token) -> Bool {
        if knownAccessTokens.contains(token.access_token) { return true }
        // The fake fixture JWTs all end with the literal string ".signature"
        // because we can't sign them — no real Tesla token does.
        if token.access_token.hasSuffix(".signature") { return true }
        if token.refresh_token.hasSuffix(".signature") { return true }
        // The fleet fixture refresh tokens use a recognisable sentinel.
        if token.refresh_token.contains("sample_fleet_refresh_token_screenshot_fixture") {
            return true
        }
        return false
    }

    static func makeOwnersToken(access: String = sampleOwnersToken,
                                refresh: String? = nil) -> Token {
        Token(
            access_token: access,
            token_type: "bearer",
            expires_in: 28800,
            refresh_token: refresh ?? access,
            expires_at: Date().addingTimeInterval(7140),
            region: .global
        )
    }

    static func makeFleetToken(prefix: String = "eu") -> Token {
        Token(
            access_token: sampleFleetToken,
            token_type: "bearer",
            expires_in: 28800,
            refresh_token: "\(prefix)_sample_fleet_refresh_token_screenshot_fixture",
            expires_at: Date().addingTimeInterval(7140),
            region: .global
        )
    }
}

#if DEBUG
import SwiftUI

@MainActor
enum ScreenshotHarness {

    /// Pre-built results used by the Test-Token screenshot so the panel
    /// looks populated without making any real network calls.
    static let fakeOwnersTestResults: [TestAPIResult] = [
        TestAPIResult(
            title: "GET /api/1/users/me",
            endpoint: "https://owner-api.teslamotors.com/api/1/users/me",
            status: .success,
            summary: "Sample User · sample@example.com"
        ),
        TestAPIResult(
            title: "GET /api/1/vehicles",
            endpoint: "https://owner-api.teslamotors.com/api/1/vehicles",
            status: .success,
            summary: "2 vehicles"
        )
    ]

    /// Convenience proxy so existing call sites that read
    /// `ScreenshotHarness.sampleOwnersToken` keep working without
    /// changes after the rename to `ScreenshotFixtures`.
    static var sampleOwnersToken: String { ScreenshotFixtures.sampleOwnersToken }

    /// Pick the initial tab the app should land on for the active scenario.
    static func initialTab() -> AppTab {
        guard let scenario = ScreenshotScenario.current else { return .owners }
        switch scenario {
        case .ownersHome, .ownersLogin, .multiAccount: return .owners
        case .fleetHome: return .fleet
        case .toolsLanding, .jwtInspector, .snippetExporter, .testToken: return .tools
        case .about: return .about
        }
    }

    /// Seeds the in-memory model for the active scenario. **Never** writes
    /// to the keychain — see the type comment at the top of this file.
    static func seed(model: AuthViewModel) async {
        let scenario = ScreenshotScenario.current ?? .ownersHome

        // Always start from a clean slate at the model level (no
        // keychain involvement).
        model.tokenV3 = nil
        model.tokenV4 = nil
        model.profilesV3 = TokenProfileCollection()
        model.profilesV4 = TokenProfileCollection()

        switch scenario {
        case .ownersLogin:
            // No tokens — login screen is what we want. Already cleared above.
            return

        case .ownersHome, .toolsLanding, .jwtInspector, .snippetExporter,
             .testToken, .about, .fleetHome:
            seedSingle(model: model)

        case .multiAccount:
            seedMultiProfile(model: model)
        }
    }

    private static func seedSingle(model: AuthViewModel) {
        let owners = ScreenshotFixtures.makeOwnersToken()
        let ownersProfile = TokenProfile(name: "Personal", token: owners)
        model.profilesV3 = TokenProfileCollection(
            profiles: [ownersProfile],
            activeProfileId: ownersProfile.id
        )
        model.tokenV3 = owners

        let fleet = ScreenshotFixtures.makeFleetToken()
        let fleetProfile = TokenProfile(name: "Production", token: fleet)
        model.profilesV4 = TokenProfileCollection(
            profiles: [fleetProfile],
            activeProfileId: fleetProfile.id
        )
        model.tokenV4 = fleet
    }

    private static func seedMultiProfile(model: AuthViewModel) {
        // Owners — three profiles to show the switcher.
        let personal = TokenProfile(name: "Personal", token: ScreenshotFixtures.makeOwnersToken())
        let work = TokenProfile(
            name: "Work",
            token: ScreenshotFixtures.makeOwnersToken(access: ScreenshotFixtures.sampleOwnersTokenWork)
        )
        let test = TokenProfile(name: "Test", token: ScreenshotFixtures.makeOwnersToken())

        model.profilesV3 = TokenProfileCollection(
            profiles: [personal, work, test],
            activeProfileId: test.id
        )
        model.tokenV3 = test.token

        // Fleet — keep one so the Fleet tab still works if the user pokes it.
        let fleet = ScreenshotFixtures.makeFleetToken()
        let fleetProfile = TokenProfile(name: "Production", token: fleet)
        model.profilesV4 = TokenProfileCollection(
            profiles: [fleetProfile],
            activeProfileId: fleetProfile.id
        )
        model.tokenV4 = fleet
    }
}
#endif
