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

/// Trigger button + popover wrapper around `HomeViewAccountMenuContent`.
///
/// We use `Button` + `.popover(isPresented:)` instead of SwiftUI's `Menu`
/// because on Mac Catalyst the `Menu` popover renders inside the window's
/// coordinate space and gets clipped at the right edge — but `.popover`
/// renders as a real `NSPopover` that can extend outside the window
/// bounds. On iOS/iPad `.popover` adapts to a sheet/popover automatically,
/// so we keep a single code path for both platforms.
private struct HomeViewAccountMenu: View {
    @Bindable var model: AuthViewModel
    let environment: LoginEnvironment
    let collection: TokenProfileCollection
    var onAddAccount: (() -> Void)?

    @State private var isPresented = false
    @State private var renameTarget: TokenProfile?
    @State private var renameText: String = ""

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            Label("Account", systemImage: "person.crop.circle")
        }
        .labelStyle(.iconOnly)
        .foregroundStyle(Color("TeslaRed"))
        .font(.title)
        .buttonStyle(.plain)
        .accessibilityIdentifier("homeMenu")
        // Anchor the arrow to the trailing edge of the popover so it
        // points right toward the icon — that places the popover body
        // on the LEFT side of the icon, where it has plenty of horizontal
        // room. With the default `.top` arrow edge, SwiftUI on Mac
        // Catalyst centers the popover horizontally on the source and
        // shrink-wraps it to whatever space is left beside the anchor.
        .popover(isPresented: $isPresented, arrowEdge: .trailing) {
            HomeViewAccountMenuContent(
                model: model,
                environment: environment,
                collection: collection,
                onAddAccount: onAddAccount,
                renameTarget: $renameTarget,
                renameText: $renameText,
                dismiss: { isPresented = false }
            )
            .frame(minWidth: 260)
            .presentationCompactAdaptation(.popover)
        }
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

/// The body of the account popover. Lives in its own view so the
/// trigger button doesn't have to know about every action.
private struct HomeViewAccountMenuContent: View {
    @Bindable var model: AuthViewModel
    let environment: LoginEnvironment
    let collection: TokenProfileCollection
    var onAddAccount: (() -> Void)?
    @Binding var renameTarget: TokenProfile?
    @Binding var renameText: String
    let dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if collection.profiles.count > 1 {
                MenuSectionHeader("Switch Account")
                ForEach(collection.profiles) { profile in
                    MenuRow(
                        title: profile.name,
                        systemImage: profile.id == collection.activeProfileId ? "checkmark" : nil
                    ) {
                        dismiss()
                        Task { await model.switchProfile(id: profile.id, environment: environment) }
                    }
                }
                Divider().padding(.vertical, 4)
            }

            if let active = collection.activeProfile {
                MenuSectionHeader(active.name)
                MenuRow(title: "Rename", systemImage: "pencil") {
                    dismiss()
                    renameText = active.name
                    renameTarget = active
                }
                if onAddAccount != nil {
                    MenuRow(title: "Add Another Account", systemImage: "person.badge.plus") {
                        dismiss()
                        onAddAccount?()
                    }
                }
                if collection.profiles.count > 1 {
                    MenuRow(
                        title: "Delete This Account",
                        systemImage: "trash",
                        role: .destructive
                    ) {
                        dismiss()
                        model.logOut(environment: environment)
                    }
                    .accessibilityIdentifier("logoutButton")
                } else {
                    MenuRow(
                        title: "Logout",
                        systemImage: "rectangle.portrait.and.arrow.right",
                        role: .destructive
                    ) {
                        dismiss()
                        model.logOut(environment: environment)
                    }
                    .accessibilityIdentifier("logoutButton")
                }
            } else if onAddAccount != nil {
                MenuRow(title: "Add Another Account", systemImage: "person.badge.plus") {
                    dismiss()
                    onAddAccount?()
                }
            }
        }
        .padding(.vertical, 8)
    }
}

private struct MenuSectionHeader: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View {
        Text(title)
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 2)
    }
}

private struct MenuRow: View {
    let title: String
    let systemImage: String?
    var role: ButtonRole? = nil
    let action: () -> Void

    var body: some View {
        Button(role: role, action: action) {
            HStack(spacing: 12) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .frame(width: 20)
                } else {
                    Spacer().frame(width: 20)
                }
                Text(title)
                Spacer()
            }
            .contentShape(.rect)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
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
