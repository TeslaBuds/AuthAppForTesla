//
//  TokenRefreshService.swift
//  TeslaAuthKit
//
//  Refreshes a stored profile's token without ever destroying it
//  (AuthAppForTesla#49, #50).
//
//  - Single flight: one refresh per profile at a time. A second caller —
//    ⌘R pressed twice, the launch refresh overlapping the Refresh button,
//    a Shortcut running while the app is open — awaits the first
//    caller's result instead of posting the same rotating refresh token
//    again (which Tesla would refuse, because the first post rotated it).
//  - Rotation races: before a refusal is believed, the profile is read
//    again. If its refresh token changed meanwhile (another device or
//    caller rotated first and the new token synced in), that newer token
//    is the answer, not "sign in again".
//  - A refusal never deletes or rewrites the stored profile. It is noted
//    in a device-local ledger and reported as "needs sign-in"; the
//    stored token stays, so the person can still see and copy it.
//  - Offline, timeouts and server errors are "offline": nothing changes.
//  - A refreshed token is written only if the profile still holds the
//    refresh token that was refreshed; a newer rotation that landed in
//    between is kept rather than overwritten with an older one.
//

import Foundation

/// Posts a refresh token to Tesla's token endpoint.
public protocol TokenRefreshTransport: Sendable {
    func refresh(refreshToken: String, region: TokenRegion, environment: LoginEnvironment) async -> TokenEndpointResponse
}

/// The result of asking for a profile's token.
public enum TokenRefreshOutcome {
    /// There is no stored profile to refresh.
    case noToken
    /// The stored token was not due for a refresh.
    case current(Token)
    /// A new token, now stored (or a newer one another device stored).
    case refreshed(Token)
    /// Tesla refused the refresh token. The stored token is kept.
    case needsSignIn(Token, reason: String)
    /// Tesla could not be reached. The stored token is kept.
    case offline(Token, reason: String)

    /// The token to show: the stored one when a refresh did not succeed.
    public var token: Token? {
        switch self {
        case .noToken: nil
        case .current(let token), .refreshed(let token), .needsSignIn(let token, _), .offline(let token, _): token
        }
    }

    /// A token that is known to be current: nil when the refresh failed.
    public var freshToken: Token? {
        switch self {
        case .current(let token), .refreshed(let token): token
        case .noToken, .needsSignIn, .offline: nil
        }
    }
}

public actor TokenRefreshService {
    private struct FlightKey: Hashable {
        let environment: LoginEnvironment
        let profileId: UUID
    }

    private let store: TokenProfileStore
    private let transport: any TokenRefreshTransport
    private let ledger: any RefreshRejectionRecording
    private let maxAttempts: Int
    private let retryDelay: Duration
    private var inFlight: [FlightKey: Task<TokenRefreshOutcome, Never>] = [:]

    /// - Parameters:
    ///   - maxAttempts: tries per refresh when Tesla cannot be reached.
    ///   - retryDelay: the pause between those tries.
    public init(
        store: TokenProfileStore,
        transport: any TokenRefreshTransport,
        ledger: any RefreshRejectionRecording,
        maxAttempts: Int = 3,
        retryDelay: Duration = .seconds(1)
    ) {
        self.store = store
        self.transport = transport
        self.ledger = ledger
        self.maxAttempts = max(1, maxAttempts)
        self.retryDelay = retryDelay
    }

    /// Why this token's refresh token was refused on this device, if it was.
    public nonisolated func rejection(for token: Token) -> String? {
        ledger.rejection(for: token.refresh_token)
    }

    /// Returns a profile's token, refreshing it when forced or due.
    ///
    /// - Parameter profileId: the profile; nil means the active one.
    public func refresh(environment: LoginEnvironment, profileId: UUID? = nil, forceRefresh: Bool) async -> TokenRefreshOutcome {
        let collection = await store.load(environment: environment)
        let profile: TokenProfile? = if let profileId {
            collection.profiles.first(where: { $0.id == profileId })
        } else {
            collection.activeProfile
        }
        guard let profile else { return .noToken }

        let key = FlightKey(environment: environment, profileId: profile.id)
        if let running = inFlight[key] {
            return await running.value
        }
        let flight = Task { await self.perform(environment: environment, profileId: profile.id, forceRefresh: forceRefresh) }
        inFlight[key] = flight
        let outcome = await flight.value
        inFlight[key] = nil
        return outcome
    }

    private func storedProfile(_ id: UUID, environment: LoginEnvironment) async -> TokenProfile? {
        await store.load(environment: environment).profiles.first(where: { $0.id == id })
    }

    private func perform(environment: LoginEnvironment, profileId: UUID, forceRefresh: Bool) async -> TokenRefreshOutcome {
        guard let profile = await storedProfile(profileId, environment: environment) else { return .noToken }
        let token = profile.token
        let posted = token.refresh_token

        if !forceRefresh {
            if let reason = ledger.rejection(for: posted) {
                return .needsSignIn(token, reason: reason)
            }
            if (token.expires_at ?? .distantPast) > Date.now.addingTimeInterval(60) {
                return .current(token)
            }
        }

        var response = TokenEndpointResponse.unavailable(reason: "Tesla did not answer.")
        for attempt in 1...maxAttempts {
            response = await transport.refresh(refreshToken: posted, region: token.region ?? .global, environment: environment)
            guard case .unavailable = response, attempt < maxAttempts else { break }
            if retryDelay > .zero { try? await Task.sleep(for: retryDelay) }
        }

        switch response {
        case .token(let fresh):
            ledger.clearRejection(of: posted)
            guard let collection = try? await store.applyRefreshedToken(fresh, toProfile: profileId, refreshedFrom: posted, environment: environment),
                  let stored = collection.profiles.first(where: { $0.id == profileId })?.token else {
                // The store refused the write (or the profile was deleted
                // meanwhile): the new token is still the current one.
                return .refreshed(fresh)
            }
            return .refreshed(stored)

        case .rejected(let reason):
            // Another device or caller may have rotated the token first.
            if let current = await storedProfile(profileId, environment: environment),
               current.token.refresh_token != posted {
                return .refreshed(current.token)
            }
            ledger.recordRejection(of: posted, reason: reason)
            return .needsSignIn(token, reason: reason)

        case .unavailable(let reason):
            return .offline(token, reason: reason)
        }
    }
}
