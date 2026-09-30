//
//  AppCommands.swift
//  AuthAppForTesla
//
//  The Mac menu bar. Catalyst's stock menus carry document, sidebar and
//  window-tab commands this app has nothing behind (#37); they are
//  replaced here, and the app's own actions get a Tokens menu and
//  keyboard shortcuts. Every command calls the same model actions as
//  the touch UI.
//

import SwiftUI
import TeslaAuthKit

struct AppCommands: Commands {
    let model: AuthViewModel

    /// Where Help sends people: the project's public repository, the
    /// support URL recorded for the App Store listing.
    static let supportURL = URL(string: "https://github.com/TeslaBuds/AuthAppForTesla")

    @FocusedBinding(\.selectedTab) private var selectedTab: AppTab?
    @Environment(\.openURL) private var openURL

    var body: some Commands {
        // File: no documents, so no Save / Duplicate / Move / Rename /
        // Export As. New Window and Close stay.
        CommandGroup(replacing: .saveItem) {}
        CommandGroup(replacing: .importExport) {}
        CommandGroup(replacing: .printItem) {}

        // View: the Show Sidebar slot becomes the four tabs.
        CommandGroup(replacing: .sidebar) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button(tab.title, systemImage: tab.systemImage) {
                    selectedTab = tab
                }
                .keyboardShortcut(tab.keyEquivalent, modifiers: .command)
                .disabled(selectedTab == nil)
            }
        }

        CommandMenu("Tokens") {
            Button("Refresh All Tokens", systemImage: "arrow.clockwise") {
                model.refreshAll()
            }
            .keyboardShortcut("r", modifiers: .command)

            Divider()

            Button("Copy Access Token", systemImage: "doc.on.doc") {
                copy(.accessToken)
            }
            .keyboardShortcut("c", modifiers: [.command, .shift])
            .disabled(!canCopy)

            Button("Copy Refresh Token", systemImage: "doc.on.doc") {
                copy(.refreshToken)
            }
            .keyboardShortcut("r", modifiers: [.command, .shift])
            .disabled(!canCopy)
        }

        // Help: there is no help book, so point at the support page.
        CommandGroup(replacing: .help) {
            Button("Auth for Tesla Support") {
                if let url = Self.supportURL {
                    openURL(url)
                }
            }
        }
    }

    /// Copying needs a token tab in front, with a token on it.
    private var canCopy: Bool {
        guard let environment = selectedTab?.loginEnvironment else { return false }
        return model.token(for: environment) != nil
    }

    private func copy(_ type: TokenType) {
        guard let environment = selectedTab?.loginEnvironment else { return }
        model.copyToken(type, environment: environment)
    }
}
