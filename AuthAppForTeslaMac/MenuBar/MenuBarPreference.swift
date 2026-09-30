//
//  MenuBarPreference.swift
//  AuthAppForTeslaMac
//

import Foundation

/// Whether the token menu sits in the menu bar. On by default; Settings
/// switches it. The Dock icon and the window are always there.
enum MenuBarPreference {
    static let storageKey = "showsMenuBarExtra"
    /// The app's own defaults domain (not the shared app group).
    nonisolated(unsafe) static let defaults = UserDefaults()

    static var showsMenuBarExtra: Bool {
        defaults.object(forKey: storageKey) as? Bool ?? true
    }
}
