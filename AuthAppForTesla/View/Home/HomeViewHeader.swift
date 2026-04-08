//
//  HomeViewHeader.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI

struct HomeViewHeader: View {
    @Bindable var model: AuthViewModel
    let loginEnvironment: LoginEnvironment
    var onAddAccount: (() -> Void)? = nil

    private var token: Token? {
        loginEnvironment == .owner ? model.tokenV3 : model.tokenV4
    }

    private var collection: TokenProfileCollection {
        loginEnvironment == .owner ? model.profilesV3 : model.profilesV4
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HomeViewTitleRow(environment: loginEnvironment, profile: collection.activeProfile)

                if let token {
                    HomeViewTokenHealth(token: token)
                    HomeViewRegionBadge(token: token, environment: loginEnvironment)
                }
            }
            Spacer()
            HomeViewAccountMenu(
                model: model,
                environment: loginEnvironment,
                collection: collection,
                onAddAccount: onAddAccount
            )
        }
    }
}

private struct HomeViewTitleRow: View {
    let environment: LoginEnvironment
    let profile: TokenProfile?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(environment == .owner ? "Owners API" : "Fleet API")
                .font(.title)
                .bold()
            if let profile {
                Text(profile.name)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct HomeViewAccountMenu: View {
    @Bindable var model: AuthViewModel
    let environment: LoginEnvironment
    let collection: TokenProfileCollection
    var onAddAccount: (() -> Void)?
    @State private var renameTarget: TokenProfile?
    @State private var renameText: String = ""

    var body: some View {
        Menu("Account", systemImage: "person.crop.circle") {
            if collection.profiles.count > 1 {
                Section("Switch Account") {
                    ForEach(collection.profiles) { profile in
                        Button {
                            Task { await model.switchProfile(id: profile.id, environment: environment) }
                        } label: {
                            if profile.id == collection.activeProfileId {
                                Label(profile.name, systemImage: "checkmark")
                            } else {
                                Text(profile.name)
                            }
                        }
                    }
                }
            }

            if let active = collection.activeProfile {
                Section(active.name) {
                    Button("Rename", systemImage: "pencil") {
                        renameText = active.name
                        renameTarget = active
                    }
                    if onAddAccount != nil {
                        Button("Add Another Account", systemImage: "person.badge.plus") {
                            onAddAccount?()
                        }
                    }
                    if collection.profiles.count > 1 {
                        Button("Delete This Account", systemImage: "trash", role: .destructive) {
                            model.logOut(environment: environment)
                        }
                        .accessibilityIdentifier("logoutButton")
                    } else {
                        Button("Logout", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                            model.logOut(environment: environment)
                        }
                        .accessibilityIdentifier("logoutButton")
                    }
                }
            } else if onAddAccount != nil {
                Button("Add Another Account", systemImage: "person.badge.plus") {
                    onAddAccount?()
                }
            }
        }
        .labelStyle(.iconOnly)
        .foregroundStyle(Color("TeslaRed"))
        .font(.title)
        .accessibilityIdentifier("homeMenu")
        .alert("Rename Account", isPresented: Binding(
            get: { renameTarget != nil },
            set: { if !$0 { renameTarget = nil } }
        )) {
            TextField("Name", text: $renameText)
            Button("Save") {
                if let target = renameTarget {
                    let newName = renameText.trimmingCharacters(in: .whitespaces)
                    if !newName.isEmpty {
                        Task { await model.renameProfile(id: target.id, to: newName, environment: environment) }
                    }
                }
                renameTarget = nil
            }
            Button("Cancel", role: .cancel) {
                renameTarget = nil
            }
        }
    }
}

#Preview("Owners – Populated") {
    HomeViewHeader(
        model: PreviewModelFactory.populatedModel(),
        loginEnvironment: .owner
    ) { }
    .padding()
}

#Preview("Fleet – Populated") {
    HomeViewHeader(
        model: PreviewModelFactory.populatedModel(),
        loginEnvironment: .fleet
    ) { }
    .padding()
}

#Preview("Owners – Empty") {
    HomeViewHeader(model: AuthViewModel(), loginEnvironment: .owner)
        .padding()
}
