//
//  AuthViewModel.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import Foundation
import TeslaAuthKit
import WidgetKit

/// Shared observable model that holds the current authentication state
/// for both Owners API (v3) and Fleet API (v4) tokens.
@MainActor
@Observable
class AuthViewModel {
    var tokenV3: Token? {
        didSet { persistTokenSummary() }
    }

    var tokenV4: Token? {
        didSet { persistTokenSummary() }
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

    init(refresher: any ActiveTokenRefreshing = AuthController.shared) {
        // Tokens are loaded asynchronously after init via loadTokens()
        self.refresher = refresher
    }

    /// The refresh problem for an API, while it still applies to the
    /// token on screen.
    func refreshProblem(for environment: LoginEnvironment) -> TokenRefreshProblem? {
        guard let problem = refreshProblems[environment],
              problem.refreshToken == token(for: environment)?.refresh_token else { return nil }
        return problem
    }

    /// Presents a toast message.
    func showToast(_ toast: Toast) {
        self.toast = toast
    }

    /// Loads the initial token state from the AuthController actor.
    func loadTokens() async {
        tokenV3 = await refresher.activeToken(environment: .owner)
        tokenV4 = await refresher.activeToken(environment: .fleet)
        await loadProfiles()
    }

    /// Reloads both profile collections from the underlying store.
    func loadProfiles() async {
        let owners = await AuthController.shared.loadProfileState(environment: .owner)
        let fleet = await AuthController.shared.loadProfileState(environment: .fleet)
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
            try await AuthController.shared.setActiveProfile(id: id, environment: environment)
        } catch {
            report(error)
            return
        }
        await loadProfiles()
        tokenV3 = await AuthController.shared.v3Token
        tokenV4 = await AuthController.shared.v4Token

        let collection = environment == .owner ? profilesV3 : profilesV4
        if let active = collection.activeProfile {
            showToast(.success("Switched to \(active.name)."))
        }
    }

    func renameProfile(id: UUID, to name: String, environment: LoginEnvironment) async {
        do {
            try await AuthController.shared.renameProfile(id: id, to: name, environment: environment)
        } catch {
            report(error)
        }
        await loadProfiles()
    }

    func deleteProfile(id: UUID, environment: LoginEnvironment) async {
        do {
            try await AuthController.shared.deleteProfile(id: id, environment: environment)
        } catch {
            report(error)
        }
        await loadProfiles()
        tokenV3 = await AuthController.shared.v3Token
        tokenV4 = await AuthController.shared.v4Token
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

    /// Writes a lightweight token summary to the shared App Group UserDefaults
    /// so the WidgetKit extension can read expiry dates without keychain access.
    private func persistTokenSummary() {
        let defaults = UserDefaults(suiteName: "group.global")
        defaults?.set(tokenV3?.expires_at, forKey: "widget.tokenV3.expiresAt")
        defaults?.set(tokenV4?.expires_at, forKey: "widget.tokenV4.expiresAt")
        defaults?.set(tokenV3 != nil, forKey: "widget.tokenV3.hasToken")
        defaults?.set(tokenV4 != nil, forKey: "widget.tokenV4.hasToken")
        WidgetCenter.shared.reloadAllTimelines()
    }

    func logOut(environment: LoginEnvironment) {
        Task {
            await AuthController.shared.logOut(environment: environment)
            // Reload so that, if other profiles still exist, the new
            // active profile becomes visible instead of dumping the
            // user back to the sign-in screen.
            await loadProfiles()
            tokenV3 = await AuthController.shared.v3Token
            tokenV4 = await AuthController.shared.v4Token
        }
    }

    func setJwtToken(_ token: Token) {
        Task {
            await AuthController.shared.setJwtToken(token)
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
