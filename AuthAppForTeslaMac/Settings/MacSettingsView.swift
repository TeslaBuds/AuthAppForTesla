//
//  MacSettingsView.swift
//  AuthAppForTeslaMac
//
//  The Settings scene (⌘,): the menu-bar token menu, whether the synced
//  tokens can be read on this Mac, the Fleet API connection, and About.
//

import SwiftUI
import TeslaAuthKit

struct MacSettingsView: View {
    @Bindable var model: AuthViewModel

    var body: some View {
        TabView {
            Tab("General", systemImage: "gearshape") {
                GeneralSettings(model: model)
            }
            Tab("Fleet API", systemImage: "car.2.fill") {
                FleetConnectionSettings()
            }
            Tab("About", systemImage: "info.circle") {
                AboutSettings()
            }
        }
        .frame(width: 520)
        .tint(Color("TeslaRed"))
    }
}

struct GeneralSettings: View {
    @Bindable var model: AuthViewModel
    @AppStorage(MenuBarPreference.storageKey, store: MenuBarPreference.defaults) private var showsMenuBarExtra = true

    var body: some View {
        Form {
            Section {
                Toggle("Show the token menu in the menu bar", isOn: $showsMenuBarExtra)
            } footer: {
                Text("Copy any account's access or refresh token, and refresh them all, from the menu bar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Section("iCloud Keychain") {
                if model.storeProblem == nil {
                    LabeledContent("Synced tokens") {
                        Label("Readable on this Mac", systemImage: "checkmark.icloud")
                    }
                } else {
                    LabeledContent("Synced tokens") {
                        Label("Can't be read on this Mac", systemImage: "exclamationmark.icloud")
                            .foregroundStyle(.orange)
                    }
                    Text("Nothing is changed on this Mac until they can be read, so your other devices keep their tokens.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                LabeledContent("Owners API accounts", value: model.profilesV3.profiles.count, format: .number)
                LabeledContent("Fleet API accounts", value: model.profilesV4.profiles.count, format: .number)
            }
        }
        .formStyle(.grouped)
    }
}

/// The Fleet API client credentials, stored in the synced keychain like
/// the tokens (and behind the same guard).
struct FleetConnectionSettings: View {
    @State private var clientId = ""
    @State private var clientSecret = ""
    @State private var redirectUri = ""
    @State private var saved = false

    var body: some View {
        Form {
            Section {
                TextField("Client ID", text: $clientId)
                SecureField("Client Secret", text: $clientSecret)
                TextField("Redirect URI", text: $redirectUri)
            } footer: {
                Text("From your application on developer.tesla.com. Used when you sign in to the Fleet API.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack {
                Spacer()
                if saved {
                    Label("Saved", systemImage: "checkmark")
                        .foregroundStyle(.secondary)
                }
                Button("Save") {
                    Task {
                        await AuthController.shared.storeFleetConnection(clientId: clientId, clientSecret: clientSecret, redirectUri: redirectUri)
                        saved = true
                    }
                }
                .disabled(clientId.isEmpty || redirectUri.isEmpty)
            }
        }
        .formStyle(.grouped)
        .task {
            #if DEBUG
            if ScreenshotScenario.isActive { return }
            #endif
            clientId = await AuthController.shared.fleetClientId
            clientSecret = await AuthController.shared.fleetClientSecret
            redirectUri = await AuthController.shared.fleetRedirectUri
        }
        .onChange(of: [clientId, clientSecret, redirectUri]) { saved = false }
    }
}

struct AboutSettings: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Image("SetupIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .accessibilityHidden(true)
            Text("Auth for Tesla")
                .font(.title2)
                .bold()
            AppVersionLabel()
            Button("Auth for Tesla Support") {
                if let url = AppCommands.supportURL { openURL(url) }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppSpacing.xl)
    }
}
