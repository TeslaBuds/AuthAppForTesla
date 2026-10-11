//
//  HomeViewHeader.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI
import TeslaAuthKit

struct HomeViewHeader: View {
    @Bindable var model: AuthViewModel
    let loginEnvironment: LoginEnvironment
    var onAddAccount: (() -> Void)? = nil
    var onSignInAgain: (() -> Void)? = nil

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
                if let problem = model.refreshProblem(for: loginEnvironment) {
                    HomeViewRefreshProblemNotice(problem: problem, onSignInAgain: onSignInAgain)
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
    @State private var pendingDeletion: TokenProfile?

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            // Person icon + chevron together so it visibly reads as a
            // menu trigger. Without the chevron the avatar looks like
            // a static badge and most users don't realise it's tappable.
            // The HStack contentShape and explicit padding give the
            // glass capsule a comfortably large hit area instead of
            // collapsing to the icon glyphs themselves.
            HStack(spacing: 4) {
                Image(systemName: "person.crop.circle")
                Image(systemName: "chevron.down")
                    .font(.caption.weight(.bold))
            }
            .font(.title3)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .contentShape(.capsule)
            .accessibilityLabel("Account menu")
        }
        .buttonStyle(.glass(.regular.tint(Color("TeslaRed"))))
        .foregroundStyle(.white)
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
                pendingDeletion: $pendingDeletion,
                dismiss: { isPresented = false }
            )
            .frame(minWidth: 280, idealHeight: 360)
            .presentationCompactAdaptation(.popover)
        }
        .confirmationDialog(
            collection.profiles.count > 1
                ? "Delete this account?"
                : "Sign out?",
            isPresented: Binding(
                get: { pendingDeletion != nil },
                set: { if !$0 { pendingDeletion = nil } }
            ),
            titleVisibility: .visible,
            presenting: pendingDeletion
        ) { profile in
            Button(
                collection.profiles.count > 1
                    ? "Delete \"\(profile.name)\""
                    : "Sign Out",
                role: .destructive
            ) {
                model.logOut(environment: environment)
                pendingDeletion = nil
            }
            .accessibilityIdentifier("logoutConfirmButton")
            Button("Cancel", role: .cancel) {
                pendingDeletion = nil
            }
        } message: { profile in
            if collection.profiles.count > 1 {
                Text("\(profile.name)'s stored \(environment == .owner ? "Owners" : "Fleet") API token will be removed from this device. You can sign in again at any time.")
            } else {
                Text("Your stored \(environment == .owner ? "Owners" : "Fleet") API token will be removed from this device. You can sign in again at any time.")
            }
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
    @Binding var pendingDeletion: TokenProfile?
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
                    AccountNameField(model: model, environment: environment, profile: active)
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
                            pendingDeletion = active
                            dismiss()
                        } label: {
                            Label("Delete This Account", systemImage: "trash")
                        }
                        .accessibilityIdentifier("logoutButton")
                    } else {
                        Button(role: .destructive) {
                            pendingDeletion = active
                            dismiss()
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
        .insetGroupedListStyle()
        .scrollContentBackground(.hidden)
    }
}

/// The active account's name, edited in place (#55). There is no Save
/// or Cancel: the name is stored when editing ends (Return, or focus
/// moving away, or the popover closing), and Undo puts the old one back.
private struct AccountNameField: View {
    let model: AuthViewModel
    let environment: LoginEnvironment
    let profile: TokenProfile

    @Environment(\.undoManager) private var undoManager
    @State private var name: String
    @FocusState private var isFocused: Bool

    init(model: AuthViewModel, environment: LoginEnvironment, profile: TokenProfile) {
        self.model = model
        self.environment = environment
        self.profile = profile
        _name = State(initialValue: profile.name)
    }

    var body: some View {
        Label {
            TextField("Account name", text: $name)
                .focused($isFocused)
                .wordsAutocapitalized()
                .submitLabel(.done)
                .onSubmit(commit)
                .accessibilityIdentifier("accountNameField")
        } icon: {
            Image(systemName: "pencil")
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
        }
        .onChange(of: isFocused) { _, focused in
            if !focused { commit() }
        }
        .onChange(of: profile.name) { _, stored in
            if !isFocused { name = stored }
        }
        .onDisappear(perform: commit)
    }

    /// Stores the typed name. A blank name puts the stored one back.
    private func commit() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            name = profile.name
            return
        }
        guard trimmed != profile.name else { return }
        let id = profile.id
        Task {
            await model.renameProfile(id: id, to: trimmed, environment: environment, undoManager: undoManager)
        }
    }
}

#Preview("Owners – Populated") {
    HomeViewHeader(
        model: PreviewModelFactory.populatedModel(),
        loginEnvironment: .owner,
        onAddAccount: { }
    )
    .padding()
}

#Preview("Fleet – Populated") {
    HomeViewHeader(
        model: PreviewModelFactory.populatedModel(),
        loginEnvironment: .fleet,
        onAddAccount: { }
    )
    .padding()
}

#Preview("Account menu – inline rename") {
    HomeViewAccountMenuContent(
        model: PreviewModelFactory.populatedModel(),
        environment: .owner,
        collection: PreviewModelFactory.populatedModel().profilesV3,
        onAddAccount: { },
        pendingDeletion: .constant(nil),
        dismiss: { }
    )
    .frame(width: 320, height: 360)
}

#Preview("Owners – Empty") {
    HomeViewHeader(model: AuthViewModel(), loginEnvironment: .owner)
        .padding()
}
