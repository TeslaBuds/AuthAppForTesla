//
//  AuthAppForTeslaMacApp.swift
//  AuthAppForTeslaMac
//
//  Auth for Tesla for the Mac (AuthAppForTesla#44): a native SwiftUI app
//  under the iPhone app's bundle ID, replacing the Catalyst build. A window
//  with a sidebar, a menu-bar token menu, Settings, and the same Tokens
//  menu commands. Everything below the shell is Shared/ and TeslaAuthKit,
//  compiled by both apps.
//

import SwiftUI
import TeslaAuthKit

@main
struct AuthAppForTeslaMacApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: MacAppDelegate
    @State private var model = AuthViewModel()
    @AppStorage(MenuBarPreference.storageKey, store: MenuBarPreference.defaults) private var showsMenuBarExtra = true

    var body: some Scene {
        Window("Auth for Tesla", id: MainWindow.id) {
            MainWindow(model: model, initialTab: MacLaunch.initialTab)
                .task { await MacLaunch.start(model: model) }
        }
        .defaultSize(width: 980, height: 780)
        // Always opened at launch, never restored closed: the window is the app.
        .defaultLaunchBehavior(.presented)
        .restorationBehavior(.disabled)
        .windowResizability(.contentMinSize)
        .commands {
            AppCommands(model: model)
        }

        MenuBarExtra(isInserted: $showsMenuBarExtra) {
            MenuBarTokenMenu(model: model)
        } label: {
            MenuBarGlyph()
        }
        .menuBarExtraStyle(.menu)

        Settings {
            MacSettingsView(model: model)
        }
    }
}
