//
//  TeslaAppShortcutsProvider.swift
//  AuthAppForTesla
//

import AppIntents

/// Registers built-in App Shortcuts so Auth for Tesla's intents appear
/// automatically in Siri and the Shortcuts app without any user setup.
struct TeslaAppShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: GetOwnersAPIToken(),
            phrases: [
                "Get my \(.applicationName) Owners API token",
                "Get Owners API token from \(.applicationName)"
            ],
            shortTitle: "Get Owners API Token",
            systemImageName: "steeringwheel"
        )
        AppShortcut(
            intent: GetFleetAPIToken(),
            phrases: [
                "Get my \(.applicationName) Fleet API token",
                "Get Fleet API token from \(.applicationName)"
            ],
            shortTitle: "Get Fleet API Token",
            systemImageName: "car.2.fill"
        )
        AppShortcut(
            intent: RefreshOwnersAPIToken(),
            phrases: [
                "Refresh my \(.applicationName) Owners API token"
            ],
            shortTitle: "Refresh Owners API Token",
            systemImageName: "arrow.clockwise"
        )
        AppShortcut(
            intent: RefreshFleetAPIToken(),
            phrases: [
                "Refresh my \(.applicationName) Fleet API token"
            ],
            shortTitle: "Refresh Fleet API Token",
            systemImageName: "arrow.clockwise"
        )
    }
}
