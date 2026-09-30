//
//  MenuBarTokenMenu.swift
//  AuthAppForTeslaMac
//
//  The menu-bar token menu (#44, Kim's decision 1): every stored profile
//  of both APIs with how long its access token has left, copy either
//  token in one click, refresh everything, and reach the window.
//

import SwiftUI
import TeslaAuthKit

struct MenuBarTokenMenu: View {
    @Bindable var model: AuthViewModel
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        if model.storeProblem != nil {
            Text("Your synced tokens can't be read on this Mac")
        }
        MenuBarProfileSection(title: "Owners API", collection: model.profilesV3, model: model)
        MenuBarProfileSection(title: "Fleet API", collection: model.profilesV4, model: model)

        Divider()
        Button("Refresh All Tokens", systemImage: "arrow.clockwise") {
            model.refreshAll()
        }
        .disabled(model.storeProblem != nil || (model.tokenV3 == nil && model.tokenV4 == nil))

        Divider()
        Button("Open Auth for Tesla") {
            openWindow(id: MainWindow.id)
            NSApp.activate()
        }
        Button("Settings…") {
            openSettings()
            NSApp.activate()
        }
        .keyboardShortcut(",", modifiers: .command)
        Button("Quit Auth for Tesla") {
            NSApp.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }
}

/// One API's profiles: a submenu per account, titled with its expiry.
struct MenuBarProfileSection: View {
    let title: LocalizedStringKey
    let collection: TokenProfileCollection
    let model: AuthViewModel

    var body: some View {
        Section(title) {
            if collection.profiles.isEmpty {
                Text("Not signed in")
            }
            ForEach(collection.profiles) { profile in
                Menu {
                    Button("Copy Access Token", systemImage: "doc.on.doc") {
                        model.copyToken(.accessToken, from: profile)
                    }
                    Button("Copy Refresh Token", systemImage: "doc.on.doc") {
                        model.copyToken(.refreshToken, from: profile)
                    }
                } label: {
                    Text(MenuBarProfileSection.label(for: profile, isActive: profile.id == collection.activeProfile?.id))
                }
            }
        }
    }

    /// "Personal — valid for 1 hr, 58 min", with a check on the active one.
    static func label(for profile: TokenProfile, isActive: Bool, now: Date = .now) -> String {
        let name = profile.name.isEmpty ? String(localized: "Account") : profile.name
        let marker = isActive ? "✓ " : ""
        guard let expiry = StoredTokenReader.expirationDate(of: profile.token) else {
            return "\(marker)\(name)"
        }
        let remaining = expiry.timeIntervalSince(now)
        guard remaining > 0 else {
            return String(localized: "\(marker)\(name) — access token expired")
        }
        let duration = Duration.seconds(remaining).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
        return String(localized: "\(marker)\(name) — valid for \(duration)")
    }
}

/// The menu-bar glyph: the key the app's cards and onboarding draw.
struct MenuBarGlyph: View {
    var body: some View {
        Image(systemName: "key.horizontal.fill")
            .accessibilityLabel("Auth for Tesla")
    }
}
