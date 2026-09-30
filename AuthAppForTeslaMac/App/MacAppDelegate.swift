//
//  MacAppDelegate.swift
//  AuthAppForTeslaMac
//

import AppKit

/// What SwiftUI's scene API does not cover.
final class MacAppDelegate: NSObject, NSApplicationDelegate {
    /// Closing the window leaves the menu-bar token menu running, when it is shown.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        !MenuBarPreference.showsMenuBarExtra
    }

    /// A click on the Dock icon with no window open brings the window back.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool { true }
}
