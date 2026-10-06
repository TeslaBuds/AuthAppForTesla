//
//  RefreshRejectionLedger.swift
//  TeslaAuthKit
//
//  Which refresh tokens Tesla has refused, kept on this device only
//  (AuthAppForTesla#50). A refused refresh token is never answered by
//  writing to the synced profile list: that write would race the
//  device that just rotated the token and could overwrite its new one.
//  Instead the refusal is remembered here, keyed by a SHA-256 of the
//  refresh token (never the token itself). When a newer token arrives —
//  from another device or from signing in again — its fingerprint is
//  different, so the "needs sign-in" state clears by itself.
//

import Foundation
import CryptoKit

public protocol RefreshRejectionRecording: Sendable {
    /// Why this refresh token was refused, if it was.
    func rejection(for refreshToken: String) -> String?
    func recordRejection(of refreshToken: String, reason: String)
    func clearRejection(of refreshToken: String)
}

/// SHA-256 hex of a refresh token: what is stored instead of the token.
func ledgerFingerprint(_ refreshToken: String) -> String {
    SHA256.hash(data: Data(refreshToken.utf8)).map { String(format: "%02x", $0) }.joined()
}

/// The production ledger, in this device's (unsynced) user defaults.
public final class UserDefaultsRejectionLedger: RefreshRejectionRecording, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key: String
    private let lock = NSLock()
    /// Old refusals are dropped beyond this many.
    private let capacity = 32

    public init(defaults: UserDefaults = .standard, key: String = "TeslaAuth.RejectedRefreshTokens") {
        self.defaults = defaults
        self.key = key
    }

    public func rejection(for refreshToken: String) -> String? {
        lock.withLock { entries()[ledgerFingerprint(refreshToken)] }
    }

    public func recordRejection(of refreshToken: String, reason: String) {
        lock.withLock {
            var all = entries()
            if all.count >= capacity { all.removeAll() }
            all[ledgerFingerprint(refreshToken)] = reason
            defaults.set(all, forKey: key)
        }
    }

    public func clearRejection(of refreshToken: String) {
        lock.withLock {
            var all = entries()
            guard all.removeValue(forKey: ledgerFingerprint(refreshToken)) != nil else { return }
            defaults.set(all, forKey: key)
        }
    }

    private func entries() -> [String: String] {
        defaults.dictionary(forKey: key) as? [String: String] ?? [:]
    }
}

/// A ledger that forgets on exit, for tests and previews.
public final class InMemoryRejectionLedger: RefreshRejectionRecording, @unchecked Sendable {
    private let lock = NSLock()
    private var entries: [String: String] = [:]

    public init() {}

    public func rejection(for refreshToken: String) -> String? {
        lock.withLock { entries[ledgerFingerprint(refreshToken)] }
    }

    public func recordRejection(of refreshToken: String, reason: String) {
        lock.withLock { entries[ledgerFingerprint(refreshToken)] = reason }
    }

    public func clearRejection(of refreshToken: String) {
        lock.withLock { _ = entries.removeValue(forKey: ledgerFingerprint(refreshToken)) }
    }
}
