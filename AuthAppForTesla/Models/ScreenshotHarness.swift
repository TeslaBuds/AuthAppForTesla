//
//  ScreenshotHarness.swift
//  AuthAppForTesla
//
//  Bridges screenshot launch arguments to in-memory state. The XCUITest
//  target launches the app with `enable-testing` plus a `screenshot-<key>`
//  flag, and this helper seeds whichever fixtures the matching screen
//  needs (single token, multi-profile, deep-linked Tools destination …).
//

#if DEBUG
import Foundation
import SwiftUI

@MainActor
enum ScreenshotHarness {

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

    /// Seed the in-memory model + keychain for the active scenario, then
    /// return so SwiftUI renders the right state. Sets `model.tokenV3` /
    /// `model.tokenV4` directly so the UI doesn't have to wait for a
    /// keychain round-trip — important because the screenshot tests run
    /// against an empty simulator keychain that may not be writable
    /// reliably under XCUITest.
    static func seed(model: AuthViewModel) async {
        let scenario = ScreenshotScenario.current ?? .ownersHome

        // Always start from a clean slate — earlier tests in the suite
        // may have left state behind in the same simulator clone.
        await AuthController.shared.logOut(environment: .owner)
        await AuthController.shared.logOut(environment: .fleet)
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
            await seedSingle(model: model)

        case .multiAccount:
            await seedMultiProfile(model: model)
        }
    }

    private static func seedSingle(model: AuthViewModel) async {
        let owners = makeOwnersToken()
        let ownersProfile = TokenProfile(name: "Personal", token: owners)
        model.profilesV3 = TokenProfileCollection(profiles: [ownersProfile], activeProfileId: ownersProfile.id)
        model.tokenV3 = owners
        await AuthController.shared.addProfile(name: "Personal", token: owners, environment: .owner, makeActive: true)

        let fleet = makeFleetToken()
        let fleetProfile = TokenProfile(name: "Production", token: fleet)
        model.profilesV4 = TokenProfileCollection(profiles: [fleetProfile], activeProfileId: fleetProfile.id)
        model.tokenV4 = fleet
        await AuthController.shared.addProfile(name: "Production", token: fleet, environment: .fleet, makeActive: true)
    }

    private static func seedMultiProfile(model: AuthViewModel) async {
        // Owners — three profiles to show the switcher.
        let personal = TokenProfile(name: "Personal", token: makeOwnersToken())
        let work = TokenProfile(name: "Work", token: makeOwnersToken(access: sampleOwnersTokenWork))
        let test = TokenProfile(name: "Test", token: makeOwnersToken())

        model.profilesV3 = TokenProfileCollection(
            profiles: [personal, work, test],
            activeProfileId: test.id
        )
        model.tokenV3 = test.token

        await AuthController.shared.addProfile(name: "Personal", token: personal.token, environment: .owner, makeActive: false)
        await AuthController.shared.addProfile(name: "Work", token: work.token, environment: .owner, makeActive: false)
        await AuthController.shared.addProfile(name: "Test", token: test.token, environment: .owner, makeActive: true)

        // Fleet — keep one so the Fleet tab still works if the user pokes it.
        let fleet = makeFleetToken()
        let fleetProfile = TokenProfile(name: "Production", token: fleet)
        model.profilesV4 = TokenProfileCollection(profiles: [fleetProfile], activeProfileId: fleetProfile.id)
        model.tokenV4 = fleet
        await AuthController.shared.addProfile(name: "Production", token: fleet, environment: .fleet, makeActive: true)
    }
}
#endif
