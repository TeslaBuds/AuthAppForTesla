//
//  AuthViewModel.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import Foundation
import TeslaAuthKit

/// Shared observable model that holds the current authentication state
/// for both Owners API (v3) and Fleet API (v4) tokens.
@MainActor
@Observable
class AuthViewModel {
    var tokenV3: Token? {
        didSet { scheduleTokenSummary() }
    }

    var tokenV4: Token? {
        didSet { scheduleTokenSummary() }
    }

    /// All known Owners API token profiles.
    var profilesV3: TokenProfileCollection = TokenProfileCollection()
    /// All known Fleet API token profiles.
    var profilesV4: TokenProfileCollection = TokenProfileCollection()

    /// In-flight OAuth state for the Owners API sign-in.
    ///
    /// Lives on the model rather than as `@State` on the login view so it
    /// survives the SwiftUI parent rebuilding while the auth sheet is
    /// open — e.g. when the user backgrounds the app to grab a password
    /// from their password manager and comes back. With per-view
    /// `@State`, the rebuild reset `codeVerifier` to nil and the next
    /// successful redirect could never be exchanged.
    var ownersAuth: OwnersAuthInFlight?

    /// In-flight OAuth state for the Fleet API sign-in. Same rationale
    /// as `ownersAuth`.
    var fleetAuth: FleetAuthInFlight?

    /// The currently visible toast notification, if any.
    var toast: Toast?

    /// Set when the synced token items could not be read. The app then
    /// shows what it can but changes nothing, so a device without access
    /// never overwrites the lists on the person's other devices (#44).
    var storeProblem: TokenStoreError?

    /// Why the last refresh of each API's token did not succeed, keyed
    /// to the refresh token it was about. Read it with `refreshProblem(for:)`.
    private(set) var refreshProblems: [LoginEnvironment: TokenRefreshProblem] = [:]

    /// The running "refresh everything", so overlapping triggers (⌘R,
    /// the Refresh button, launch, the menu bar) join it (#50).
    private var refreshAllTask: Task<Void, Never>?

    private let refresher: any ActiveTokenRefreshing

    /// Publishes the widget's token summary (#58).
    private let summaryPublisher: TokenSummaryPublisher

    /// The pending summary write. Every token assignment made before it
    /// runs joins it, so assigning both tokens costs one write and at
    /// most one widget reload (#58). Tests await it.
    private(set) var pendingTokenSummary: Task<Void, Never>?

    /// The running `startObservingStore()` loop.
    @ObservationIgnored private var storeObservation: Task<Void, Never>?

    /// The last rename's store write; undo and redo start one. Tests await it.
    @ObservationIgnored private(set) var pendingRename: Task<Void, Never>?

    /// How many token assignments asked for a summary write. Before #58
    /// each one wrote the summary and reloaded every widget timeline.
    @ObservationIgnored private(set) var tokenSummaryRequests = 0

    /// Speaks every toast, which is otherwise only seen (#57).
    private let announcer: AccessibilityAnnouncer

    /// The token store and its operations. Tests pass one over an
    /// in-memory store.
    let controller: AuthController

    init(refresher: (any ActiveTokenRefreshing)? = nil,
         summaryPublisher: TokenSummaryPublisher = .live,
         announcer: AccessibilityAnnouncer = .live,
         controller: AuthController = .shared) {
        // Tokens are loaded asynchronously after init via loadTokens()
        self.refresher = refresher ?? controller
        self.summaryPublisher = summaryPublisher
        self.announcer = announcer
        self.controller = controller
    }

    /// The refresh problem for an API, while it still applies to the
    /// token on screen.
    func refreshProblem(for environment: LoginEnvironment) -> TokenRefreshProblem? {
        guard let problem = refreshProblems[environment],
              problem.refreshToken == token(for: environment)?.refresh_token else { return nil }
        return problem
    }

    /// Presents a toast message, and speaks it (#57).
    func showToast(_ toast: Toast) {
        self.toast = toast
        announcer.announce(toast.message)
    }

    /// Reloads tokens and profiles whenever the controller changes the
    /// store — a Shortcut run in this process included (#52). Idempotent.
    func startObservingStore() {
        guard storeObservation == nil else { return }
        let controller = controller
        storeObservation = Task { [weak self] in
            for await _ in NotificationCenter.default.notifications(named: AuthController.storeDidChange, object: controller) {
                guard let self else { return }
                await self.reloadFromStore()
            }
        }
    }

    /// Re-reads tokens and profiles from the store, e.g. when the app
    /// comes back to the foreground or the menu-bar menu opens after a
    /// Shortcut ran elsewhere (#52). The App Store screenshot fixture
    /// lives only in the model, so it is left alone.
    func reloadFromStore() async {
        #if DEBUG
        if ScreenshotScenario.isActive { return }
        #endif
        await loadTokens()
    }

    /// Loads the initial token state from the AuthController actor.
    func loadTokens() async {
        let owners = await refresher.activeToken(environment: .owner)
        let fleet = await refresher.activeToken(environment: .fleet)
        setTokens(owners: owners, fleet: fleet)
        await loadProfiles()
    }

    /// Shows both active tokens at once, so the widget summary is written
    /// once for the pair (#58).
    private func setTokens(owners: Token?, fleet: Token?) {
        tokenV3 = owners
        tokenV4 = fleet
    }

    /// Reads both active tokens back from the store after a profile change.
    private func reloadActiveTokens() async {
        let owners = await controller.v3Token
        let fleet = await controller.v4Token
        setTokens(owners: owners, fleet: fleet)
    }

    /// Reloads both profile collections from the underlying store.
    func loadProfiles() async {
        let owners = await controller.loadProfileState(environment: .owner)
        let fleet = await controller.loadProfileState(environment: .fleet)
        profilesV3 = owners.collection
        profilesV4 = fleet.collection
        storeProblem = [owners, fleet].lazy.compactMap { state -> TokenStoreError? in
            if case .unavailable(let error) = state { return error }
            return nil
        }.first
    }

    /// Shows why a profile change was refused.
    private func report(_ error: TokenStoreError) {
        storeProblem = error
        showToast(.error(error.message))
    }

    /// Activates a different profile and reloads the active token mirror.
    func switchProfile(id: UUID, environment: LoginEnvironment) async {
        do {
            try await controller.setActiveProfile(id: id, environment: environment)
        } catch {
            report(error)
            return
        }
        await loadProfiles()
        await reloadActiveTokens()

        let collection = environment == .owner ? profilesV3 : profilesV4
        if let active = collection.activeProfile {
            showToast(.success("Switched to \(active.name)."))
        }
    }

    /// Renames a profile at once — there is no Save or Cancel (#55).
    /// The previous name is registered with `undoManager`, so ⌘Z or
    /// shake to undo puts it back, and redo renames it again.
    func renameProfile(id: UUID, to name: String, environment: LoginEnvironment, undoManager: UndoManager? = nil) async {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let collection = environment == .owner ? profilesV3 : profilesV4
        guard !trimmed.isEmpty,
              let previous = collection.profiles.first(where: { $0.id == id })?.name,
              previous != trimmed else { return }
        guard await applyRename(id: id, to: trimmed, environment: environment) else { return }
        registerRenameUndo(id: id, restoring: previous, replacing: trimmed, environment: environment, undoManager: undoManager)
    }

    /// Registers the step back to `restoring`. Running it registers the
    /// step forward again, which is how UndoManager offers redo.
    private func registerRenameUndo(id: UUID, restoring: String, replacing: String, environment: LoginEnvironment, undoManager: UndoManager?) {
        guard let undoManager else { return }
        undoManager.registerUndo(withTarget: self) { model in
            MainActor.assumeIsolated {
                model.registerRenameUndo(id: id, restoring: replacing, replacing: restoring, environment: environment, undoManager: undoManager)
                model.pendingRename = Task { await model.applyRename(id: id, to: restoring, environment: environment) }
            }
        }
        undoManager.setActionName(String(localized: "Rename Account"))
    }

    /// Writes a new name; false when the store refused it.
    @discardableResult
    private func applyRename(id: UUID, to name: String, environment: LoginEnvironment) async -> Bool {
        var succeeded = true
        do {
            try await controller.renameProfile(id: id, to: name, environment: environment)
        } catch {
            report(error)
            succeeded = false
        }
        await loadProfiles()
        return succeeded
    }

    func deleteProfile(id: UUID, environment: LoginEnvironment) async {
        do {
            try await controller.deleteProfile(id: id, environment: environment)
        } catch {
            report(error)
        }
        await loadProfiles()
        await reloadActiveTokens()
    }

    /// Refreshes both APIs' active tokens. A token that could not be
    /// refreshed stays on screen: offline is not signed out, and a refused
    /// refresh token is flagged, never deleted (#49, #50). Calls made while
    /// one is running join it instead of posting the same tokens again.
    @discardableResult
    func refreshAll() -> Task<Void, Never> {
        if let refreshAllTask { return refreshAllTask }
        let task = Task {
            await performRefreshAll()
            refreshAllTask = nil
        }
        refreshAllTask = task
        return task
    }

    private func performRefreshAll() async {
        let owners = await refresher.refreshActive(environment: .owner, forceRefresh: true)
        let fleet = await refresher.refreshActive(environment: .fleet, forceRefresh: true)
        apply(owners, environment: .owner)
        apply(fleet, environment: .fleet)
        if let toast = Self.toast(owners: owners, fleet: fleet) {
            showToast(toast)
        }
    }

    /// Shows a refresh outcome. Only a successful refresh replaces the
    /// token; nothing here ever clears one.
    private func apply(_ outcome: TokenRefreshOutcome, environment: LoginEnvironment) {
        guard let token = outcome.token else { return }
        switch environment {
        case .owner: tokenV3 = token
        case .fleet: tokenV4 = token
        }
        refreshProblems[environment] = TokenRefreshProblem(outcome)
    }

    /// The toast after "refresh everything": success only when every
    /// refresh that was attempted succeeded.
    static func toast(owners: TokenRefreshOutcome, fleet: TokenRefreshOutcome) -> Toast? {
        let outcomes = [(String(localized: "Owners API"), owners), (String(localized: "Fleet API"), fleet)]
        let refused = outcomes.compactMap { name, outcome -> String? in
            if case .needsSignIn(_, let reason) = outcome { return "\(name): \(reason)" }
            return nil
        }
        if !refused.isEmpty {
            return .error(String(localized: "Tesla refused a refresh token. Sign in again to replace it. (\(refused.joined(separator: "; ")))"))
        }
        if outcomes.contains(where: { if case .offline = $0.1 { true } else { false } }) {
            return .error(String(localized: "Couldn't reach Tesla. Your saved tokens are unchanged."))
        }
        if outcomes.contains(where: { $0.1.freshToken != nil }) {
            return .success(String(localized: "Tokens refreshed successfully."))
        }
        return nil
    }

    /// The active token for an API, as currently shown in the UI.
    func token(for environment: LoginEnvironment) -> Token? {
        switch environment {
        case .owner: tokenV3
        case .fleet: tokenV4
        }
    }

    /// Copies the active access or refresh token for an API to the
    /// clipboard and confirms it with a toast. Used by the Mac menu
    /// bar's copy commands.
    func copyToken(_ type: TokenType, environment: LoginEnvironment) {
        guard let token = token(for: environment) else {
            showToast(.error("There is no token to copy. Please sign in first."))
            return
        }
        switch type {
        case .accessToken:
            TokenClipboard.copy(token.access_token)
            showToast(.success("Access token copied."))
        case .refreshToken:
            TokenClipboard.copy(token.refresh_token)
            showToast(.success("Refresh token copied."))
        }
    }

    /// Copies one profile's access or refresh token, whichever profile is
    /// active. Used by the Mac's menu-bar token menu.
    func copyToken(_ type: TokenType, from profile: TokenProfile) {
        let name = profile.name.isEmpty ? "the account" : profile.name
        switch type {
        case .accessToken:
            TokenClipboard.copy(profile.token.access_token)
            showToast(.success("Access token for \(name) copied."))
        case .refreshToken:
            TokenClipboard.copy(profile.token.refresh_token)
            showToast(.success("Refresh token for \(name) copied."))
        }
    }

    /// Queues one write of the widget's token summary to the shared App
    /// Group UserDefaults, so the WidgetKit extension can read expiry dates
    /// without keychain access. Assignments made before the write runs join
    /// it; the write itself does nothing when the summary is unchanged (#58).
    private func scheduleTokenSummary() {
        tokenSummaryRequests += 1
        guard pendingTokenSummary == nil else { return }
        pendingTokenSummary = Task { [weak self] in
            guard let self else { return }
            pendingTokenSummary = nil
            summaryPublisher.publish(TokenSummary(owners: tokenV3, fleet: tokenV4))
        }
    }

    func logOut(environment: LoginEnvironment) {
        Task {
            await controller.logOut(environment: environment)
            // Reload so that, if other profiles still exist, the new
            // active profile becomes visible instead of dumping the
            // user back to the sign-in screen.
            await loadProfiles()
            await reloadActiveTokens()
        }
    }

    func setJwtToken(_ token: Token) {
        Task {
            await controller.setJwtToken(token)
        }
        tokenV3 = token
    }
}

/// Snapshot of an Owners API OAuth flow that's currently between
/// "build authorize URL" and "exchange code for token". Identifiable
/// so it can drive `.sheet(item:)`; a stable id (UUID per flow) keeps
/// SwiftUI from recreating the auth sheet's content view if the model
/// republishes for unrelated reasons.
///
/// Carries a `TeslaAuthSession` (long-lived `WKWebView` + nav
/// delegate) so the in-flight auth WebView survives SwiftUI parent
/// view rebuilds — without it the user loses anything they've typed
/// when iOS reactivates the app from a password-manager hop.
struct OwnersAuthInFlight: Identifiable, Equatable {
    let id = UUID()
    var url: URL
    var codeVerifier: String
    /// The random `state` sent; the redirect must carry it back (#51).
    var state: String
    var region: TokenRegion
    var addAsNewProfile: Bool
    let session: TeslaAuthSession

    static func == (lhs: OwnersAuthInFlight, rhs: OwnersAuthInFlight) -> Bool {
        lhs.id == rhs.id
    }
}

/// Snapshot of a Fleet API OAuth flow in flight. Carries the
/// developer-supplied client credentials so the code exchange can
/// complete with the same values the URL was built from, even if the
/// user has navigated away from the login view since. Also carries
/// the `TeslaAuthSession` (see `OwnersAuthInFlight` for rationale).
struct FleetAuthInFlight: Identifiable, Equatable {
    let id = UUID()
    var url: URL
    /// The random `state` sent; the redirect must carry it back (#51).
    var state: String
    var region: TokenRegion
    var clientId: String
    var clientSecret: String
    var redirectUri: String
    var addAsNewProfile: Bool
    let session: TeslaAuthSession

    static func == (lhs: FleetAuthInFlight, rhs: FleetAuthInFlight) -> Bool {
        lhs.id == rhs.id
    }
}
