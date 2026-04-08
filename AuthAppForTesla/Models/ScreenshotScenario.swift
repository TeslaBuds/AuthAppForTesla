//
//  ScreenshotScenario.swift
//  AuthAppForTesla
//
//  Launch-argument helpers used to drive App Store screenshot capture.
//  The XCUITest target launches the app with `enable-testing` plus a
//  `screenshot-<key>` flag, and the app reads this enum to seed token
//  fixtures and deep-link to the right screen.
//

#if DEBUG
import Foundation

enum ScreenshotScenario: String {
    case ownersHome   = "screenshot-owners-home"
    case ownersLogin  = "screenshot-owners-login"
    case fleetHome    = "screenshot-fleet-home"
    case toolsLanding = "screenshot-tools"
    case jwtInspector = "screenshot-jwt-inspector"
    case snippetExporter = "screenshot-snippet-exporter"
    case testToken    = "screenshot-test-token"
    case multiAccount = "screenshot-multi-account"
    case about        = "screenshot-about"

    /// Detects whichever screenshot scenario was passed via CLI arguments.
    static var current: ScreenshotScenario? {
        let args = Set(CommandLine.arguments)
        for scenario in allCases where args.contains(scenario.rawValue) {
            return scenario
        }
        return nil
    }

    /// Whether the screenshot harness is active at all.
    static var isActive: Bool {
        CommandLine.arguments.contains("enable-testing")
    }
}

extension ScreenshotScenario: CaseIterable {}
#endif
