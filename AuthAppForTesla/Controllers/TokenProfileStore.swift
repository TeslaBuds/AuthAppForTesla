//
//  TokenProfileStore.swift
//  AuthAppForTesla
//
//  Persistence for named Owners and Fleet API token profiles. Wraps
//  the existing keychain layout: profile collections live under their
//  own keys, while the legacy single-token keys (kTokenV3 / kTokenV4)
//  are kept in sync with the active profile so the widget extension
//  and AppIntents continue to work without changes.
//
//  THE SYNC-WIPE GUARD (AuthAppForTesla#44). Every profile list is one
//  iCloud-synchronised keychain item. A device that cannot read that
//  item — a Mac whose signature lacks `group.global`, a locked
//  keychain, data written by a newer version — must never write a list
//  it did not first read, because iCloud Keychain would carry that
//  write to the iPhone and wipe it. So:
//
//  - a read that *failed* (any status other than success or not-found)
//    blocks every write for that environment, including the legacy
//    migration and the legacy mirror;
//  - data that does not decode blocks every write (never overwritten);
//  - a list that was *not found* is only ever created with an add that
//    refuses to overwrite; if one appeared meanwhile, the change is
//    re-applied to the list that is actually there;
//  - a list that was read is replaced only if it is still byte-for-byte
//    what was read (compare-and-swap), otherwise the change is
//    re-applied to the fresh list;
//  - an empty list is never written, except when the person deletes
//    the last profile of a list that was read successfully.
//

import Foundation

let kTokenV3Profiles = "dk.kimhansen.TeslaAuth.TokenV3Profiles"
let kTokenV4Profiles = "dk.kimhansen.TeslaAuth.TokenV4Profiles"

/// Why the profile store refused to change anything.
enum TokenStoreError: Error, Equatable {
    /// The keychain refused the read, with this status. Nothing was written.
    case unreadable(OSStatus)
    /// The stored list exists but does not decode. Nothing was written.
    case undecodable
    /// The change would have written an empty list. Nothing was written.
    case refusedEmptyWrite
    /// The list kept changing under the store (another device syncing).
    case changedSinceRead
    /// The keychain refused the write itself, with this status.
    case writeFailed(OSStatus)
}

extension TokenStoreError {
    /// What the person is told when a change was refused.
    var message: String {
        switch self {
        case .unreadable, .undecodable:
            "Your synced tokens can't be read on this device, so nothing was changed."
        case .refusedEmptyWrite:
            "Nothing was changed."
        case .changedSinceRead:
            "Your tokens changed on another device. Please try again."
        case .writeFailed:
            "The change couldn't be saved."
        }
    }
}

/// How the stored profiles looked when read, for the UI: an unreadable
/// store is not the same as a signed-out one.
enum TokenProfileLoadState {
    case loaded(TokenProfileCollection)
    case unavailable(TokenStoreError)

    var collection: TokenProfileCollection {
        if case .loaded(let collection) = self { return collection }
        return TokenProfileCollection()
    }
}

/// The keychain operations the store needs, each reporting its status.
/// The live implementation is `KeychainWrapper`; tests substitute fakes
/// and real keychains with other access groups.
protocol SyncedItemStorage: Sendable {
    func read(_ key: String) -> KeychainReadResult
    /// Creates an item; `errSecDuplicateItem` when one exists. Never overwrites.
    func add(_ data: Data, forKey key: String) -> OSStatus
    /// Replaces an existing item's data.
    func replace(_ data: Data, forKey key: String) -> OSStatus
    func remove(_ key: String) -> OSStatus
}

/// `KeychainWrapper` as the store's storage, with the accessibility every
/// Auth for Tesla item has always used.
struct KeychainSyncedItemStorage: SyncedItemStorage, @unchecked Sendable {
    let keychain: KeychainWrapper

    func read(_ key: String) -> KeychainReadResult {
        keychain.readResult(forKey: key, withAccessibility: .afterFirstUnlock)
    }

    func add(_ data: Data, forKey key: String) -> OSStatus {
        keychain.addOnly(data, forKey: key, withAccessibility: .afterFirstUnlock)
    }

    func replace(_ data: Data, forKey key: String) -> OSStatus {
        keychain.updateOnly(data, forKey: key, withAccessibility: .afterFirstUnlock)
    }

    func remove(_ key: String) -> OSStatus {
        keychain.removeReturningStatus(forKey: key, withAccessibility: .afterFirstUnlock)
    }
}

actor TokenProfileStore {
    static let shared = TokenProfileStore(storage: KeychainSyncedItemStorage(keychain: .global))

    private let storage: any SyncedItemStorage
    /// How many times a change is re-applied when the list moved under it.
    private let maxAttempts = 3

    init(storage: any SyncedItemStorage) {
        self.storage = storage
    }

    // MARK: - Loading

    /// The profile collection for an environment, or an empty one when
    /// the store could not be read. Use `loadState` where the difference
    /// matters to the person.
    func load(environment: LoginEnvironment) -> TokenProfileCollection {
        loadState(environment: environment).collection
    }

    /// Loads the profile collection, lazily migrating an existing legacy
    /// single-token entry into a "Default" profile on first read — but
    /// only when both reads succeeded.
    func loadState(environment: LoginEnvironment) -> TokenProfileLoadState {
        switch basis(for: environment) {
        case .blocked(let error):
            return .unavailable(error)
        case .stored(_, let collection):
            return .loaded(collection)
        case .absent(let migrated):
            guard let migrated else { return .loaded(TokenProfileCollection()) }
            // First-time access with a legacy token: persist the migration.
            // A refusal is not fatal: the migrated view is still correct
            // and the migration is retried on the next read.
            _ = try? mutate(environment: environment) { _ in }
            return .loaded(migrated)
        }
    }

    // MARK: - Mutations

    /// Adds or updates a profile, optionally promoting it to active.
    @discardableResult
    func upsert(profile: TokenProfile, environment: LoginEnvironment, makeActive: Bool) throws(TokenStoreError) -> TokenProfileCollection {
        try mutate(environment: environment) { collection in
            collection.upsert(profile)
            if makeActive {
                collection.activeProfileId = profile.id
            }
        }
    }

    /// Updates the token for a specific profile (regardless of active
    /// status). Used by App Intents that operate on a chosen account
    /// rather than the active one. If the profile id is unknown the
    /// collection is returned unchanged.
    @discardableResult
    func updateProfileToken(id: UUID, token: Token, environment: LoginEnvironment) throws(TokenStoreError) -> TokenProfileCollection {
        try mutate(environment: environment) { collection in
            guard let index = collection.profiles.firstIndex(where: { $0.id == id }) else { return }
            collection.profiles[index].token = token
        }
    }

    /// Updates the token for the currently active profile (used by token
    /// refreshes). If no profiles exist, creates a Default one.
    @discardableResult
    func updateActiveToken(_ token: Token, environment: LoginEnvironment) throws(TokenStoreError) -> TokenProfileCollection {
        let name = defaultProfileName(for: environment)
        return try mutate(environment: environment) { collection in
            if let activeId = collection.activeProfileId,
               let index = collection.profiles.firstIndex(where: { $0.id == activeId }) {
                collection.profiles[index].token = token
            } else if var profile = collection.activeProfile {
                profile.token = token
                collection.upsert(profile)
            } else {
                collection.upsert(TokenProfile(name: name, token: token))
            }
        }
    }

    @discardableResult
    func setActive(id: UUID, environment: LoginEnvironment) throws(TokenStoreError) -> TokenProfileCollection {
        try mutate(environment: environment) { collection in
            guard collection.profiles.contains(where: { $0.id == id }) else { return }
            collection.activeProfileId = id
        }
    }

    @discardableResult
    func rename(id: UUID, to name: String, environment: LoginEnvironment) throws(TokenStoreError) -> TokenProfileCollection {
        try mutate(environment: environment) { collection in
            collection.rename(id: id, to: name)
        }
    }

    /// Deletes a profile. The only change allowed to leave a list empty,
    /// and only for a list that was read successfully.
    @discardableResult
    func delete(id: UUID, environment: LoginEnvironment) throws(TokenStoreError) -> TokenProfileCollection {
        try mutate(environment: environment, allowsEmpty: true) { collection in
            collection.remove(id: id)
        }
    }

    /// Removes the legacy single-token mirror after its refresh token was
    /// rejected — the long-standing iOS behaviour — but only when the
    /// profile list could be read, so a device that cannot see the synced
    /// items never deletes one.
    func clearLegacyMirror(environment: LoginEnvironment) throws(TokenStoreError) {
        if case .blocked(let error) = basis(for: environment) { throw error }
        let status = storage.remove(legacyKey(for: environment))
        guard status == errSecSuccess || status == errSecItemNotFound else { throw .writeFailed(status) }
    }

    /// Suggests a sensible name for the next "Add Account" profile, e.g.
    /// "Account 2" / "Account 3" so the user doesn't have to type one.
    func suggestedName(for environment: LoginEnvironment) -> String {
        let collection = load(environment: environment)
        let next = collection.profiles.count + 1
        return "Account \(next)"
    }

    // MARK: - The guarded write

    /// What a write may be based on.
    private enum Basis {
        /// The list exists and decoded; `data` is exactly what was read.
        case stored(data: Data, collection: TokenProfileCollection)
        /// There is no list. `migrated` is the legacy token folded into
        /// one, when a legacy entry exists.
        case absent(migrated: TokenProfileCollection?)
        /// Nothing may be written.
        case blocked(TokenStoreError)
    }

    private func basis(for environment: LoginEnvironment) -> Basis {
        switch storage.read(profilesKey(for: environment)) {
        case .failed(let status):
            return .blocked(.unreadable(status))
        case .found(let data):
            guard let collection = try? JSONDecoder().decode(TokenProfileCollection.self, from: data) else {
                return .blocked(.undecodable)
            }
            return .stored(data: data, collection: collection)
        case .notFound:
            switch storage.read(legacyKey(for: environment)) {
            case .failed(let status):
                return .blocked(.unreadable(status))
            case .notFound:
                return .absent(migrated: nil)
            case .found(let data):
                guard let legacy = try? JSONDecoder().decode(Token.self, from: data) else {
                    return .absent(migrated: nil)
                }
                var collection = TokenProfileCollection()
                collection.upsert(TokenProfile(name: defaultProfileName(for: environment), token: legacy))
                return .absent(migrated: collection)
            }
        }
    }

    /// Reads, applies `change`, and writes back only what the guard allows.
    @discardableResult
    private func mutate(
        environment: LoginEnvironment,
        allowsEmpty: Bool = false,
        _ change: (inout TokenProfileCollection) -> Void
    ) throws(TokenStoreError) -> TokenProfileCollection {
        let key = profilesKey(for: environment)
        for _ in 0..<maxAttempts {
            var collection: TokenProfileCollection
            let original: Data?
            switch basis(for: environment) {
            case .blocked(let error):
                throw error
            case .stored(let data, let stored):
                collection = stored
                original = data
            case .absent(let migrated):
                collection = migrated ?? TokenProfileCollection()
                original = nil
            }

            change(&collection)

            if collection.profiles.isEmpty {
                // Nothing to create where nothing exists.
                if original == nil { return collection }
                guard allowsEmpty else { throw .refusedEmptyWrite }
            }

            guard let data = try? JSONEncoder().encode(collection) else { throw .undecodable }
            let status: OSStatus
            if let original {
                // Compare-and-swap: replace only what was read.
                guard case .found(let current) = storage.read(key) else { continue }
                guard current == original else { continue }
                if current == data {
                    status = errSecSuccess
                } else {
                    status = storage.replace(data, forKey: key)
                }
            } else {
                status = storage.add(data, forKey: key)
            }

            switch status {
            case errSecSuccess:
                mirrorLegacy(collection, environment: environment)
                return collection
            case errSecDuplicateItem, errSecItemNotFound:
                // The list appeared or vanished since it was read:
                // re-apply the change to what is there now.
                continue
            default:
                throw .writeFailed(status)
            }
        }
        throw .changedSinceRead
    }

    /// Mirrors the active profile's token to the legacy single-token
    /// keychain entry so the widget summary and older readers see the
    /// right value. Runs only after the list itself was written.
    private func mirrorLegacy(_ collection: TokenProfileCollection, environment: LoginEnvironment) {
        let legacyKey = legacyKey(for: environment)
        guard let active = collection.activeProfile,
              let encoded = try? JSONEncoder().encode(active.token) else {
            _ = storage.remove(legacyKey)
            return
        }
        switch storage.read(legacyKey) {
        case .found(let existing):
            if existing != encoded { _ = storage.replace(encoded, forKey: legacyKey) }
        case .notFound:
            _ = storage.add(encoded, forKey: legacyKey)
        case .failed:
            break
        }
    }

    // MARK: - Keys

    private func profilesKey(for environment: LoginEnvironment) -> String {
        switch environment {
        case .owner: kTokenV3Profiles
        case .fleet: kTokenV4Profiles
        }
    }

    private func legacyKey(for environment: LoginEnvironment) -> String {
        switch environment {
        case .owner: kTokenV3
        case .fleet: kTokenV4
        }
    }

    private func defaultProfileName(for environment: LoginEnvironment) -> String {
        switch environment {
        case .owner: "Owners Account"
        case .fleet: "Fleet Account"
        }
    }
}
