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

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            // Person icon + chevron together so it visibly reads as a
            // menu trigger. Without the chevron the avatar looks like
            // a static badge and most users don't realise it's tappable.
            HStack(spacing: 4) {
                Image(systemName: "person.crop.circle")
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
            }
            .accessibilityLabel("Account menu")
        }
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
                dismiss: { isPresented = false }
            )
            .frame(minWidth: 280, idealHeight: 360)
            .presentationCompactAdaptation(.popover)
        }
        // SwiftUI alerts don't honor .buttonStyle, so we can't override
        // the inherited TeslaRed tint that bleeds into Save and Cancel.
        // Use a small sheet with a real Form instead so Save can be
        // .borderedProminent and Cancel can be the system default.
        .sheet(item: $renameTarget) { target in
            RenameAccountSheet(
                initialName: target.name,
                onSave: { newName in
                    Task {
                        await model.renameProfile(id: target.id, to: newName, environment: environment)
                    }
                    renameTarget = nil
                },
                onCancel: {
                    renameTarget = nil
                }
            )
        }
    }
}

/// The body of the account popover. Uses a `List` so each row gets a
/// canonical menu-row hit target (full row width, hover highlight,
/// proper tap behavior on every Apple platform). The previous VStack
/// approach with `.contentShape(.rect)` had a hit area that collapsed
/// to the visible text bounds on Mac Catalyst, so users could only
/// click directly on the row label.
private struct HomeViewAccountMenuContent: View {
    @Bindable var model: AuthViewModel
    let environment: LoginEnvironment
    let collection: TokenProfileCollection
    var onAddAccount: (() -> Void)?
    @Binding var renameTarget: TokenProfile?
    let dismiss: () -> Void

    var body: some View {
        List {
            if collection.profiles.count > 1 {
                Section("Switch Account") {
                    ForEach(collection.profiles) { profile in
                        Button {
                            dismiss()
                            Task {
                                await model.switchProfile(
                                    id: profile.id,
                                    environment: environment
                                )
                            }
                        } label: {
                            Label {
                                Text(profile.name)
                                    .foregroundStyle(.primary)
                            } icon: {
                                if profile.id == collection.activeProfileId {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color("TeslaRed"))
                                } else {
                                    Image(systemName: "circle")
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }

            if let active = collection.activeProfile {
                Section(active.name) {
                    Button {
                        renameTarget = active
                        dismiss()
                    } label: {
                        Label("Rename", systemImage: "pencil")
                            .foregroundStyle(.primary)
                    }
                    if onAddAccount != nil {
                        Button {
                            dismiss()
                            onAddAccount?()
                        } label: {
                            Label("Add Another Account", systemImage: "person.badge.plus")
                                .foregroundStyle(.primary)
                        }
                    }
                    if collection.profiles.count > 1 {
                        Button(role: .destructive) {
                            dismiss()
                            model.logOut(environment: environment)
                        } label: {
                            Label("Delete This Account", systemImage: "trash")
                        }
                        .accessibilityIdentifier("logoutButton")
                    } else {
                        Button(role: .destructive) {
                            dismiss()
                            model.logOut(environment: environment)
                        } label: {
                            Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                        .accessibilityIdentifier("logoutButton")
                    }
                }
            } else if onAddAccount != nil {
                Section {
                    Button {
                        dismiss()
                        onAddAccount?()
                    } label: {
                        Label("Add Another Account", systemImage: "person.badge.plus")
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }
}

/// Sheet-based rename form. Used instead of `.alert` because alerts
/// don't honor `.buttonStyle`, so the inherited TeslaRed tint at the
/// RootView level can't be overridden — Save and Cancel ended up
/// rendering in alarming red even though neither action is destructive.
private struct RenameAccountSheet: View {
    let initialName: String
    let onSave: (String) -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @FocusState private var isNameFocused: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Account name", text: $name)
                        .focused($isNameFocused)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                        .onSubmit(saveIfValid)
                }
            }
            .navigationTitle("Rename Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: saveIfValid)
                        .buttonStyle(.borderedProminent)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear {
                name = initialName
                // Defer focus a hair so the sheet finishes presenting first.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    isNameFocused = true
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func saveIfValid() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        onSave(trimmed)
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
