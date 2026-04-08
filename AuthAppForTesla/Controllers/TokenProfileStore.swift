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

import Foundation

let kTokenV3Profiles = "dk.kimhansen.TeslaAuth.TokenV3Profiles"
let kTokenV4Profiles = "dk.kimhansen.TeslaAuth.TokenV4Profiles"

actor TokenProfileStore {
    static let shared = TokenProfileStore()

    private init() {}

    // MARK: - Loading

    /// Loads the profile collection for an environment, lazily migrating
    /// any existing legacy single-token keychain entry into a "Default"
    /// profile on first read.
    func load(environment: LoginEnvironment) -> TokenProfileCollection {
        let key = profilesKey(for: environment)
        if let data = KeychainWrapper.global.data(forKey: key, withAccessibility: .afterFirstUnlock),
           let collection = try? JSONDecoder().decode(TokenProfileCollection.self, from: data) {
            return collection
        }

        // First-time access — migrate legacy single-token storage if any.
        if let legacy = legacyToken(for: environment) {
            var collection = TokenProfileCollection()
            let profile = TokenProfile(name: defaultProfileName(for: environment), token: legacy)
            collection.upsert(profile)
            persist(collection, environment: environment)
            return collection
        }

        return TokenProfileCollection()
    }

    // MARK: - Mutations

    /// Adds or updates a profile, optionally promoting it to active.
    @discardableResult
    func upsert(profile: TokenProfile, environment: LoginEnvironment, makeActive: Bool) -> TokenProfileCollection {
        var collection = load(environment: environment)
        collection.upsert(profile)
        if makeActive {
            collection.activeProfileId = profile.id
        }
        persist(collection, environment: environment)
        return collection
    }

    /// Updates the token for the currently active profile (used by token
    /// refreshes). If no profiles exist, creates a Default one.
    @discardableResult
    func updateActiveToken(_ token: Token, environment: LoginEnvironment) -> TokenProfileCollection {
        var collection = load(environment: environment)
        if let activeId = collection.activeProfileId,
           let index = collection.profiles.firstIndex(where: { $0.id == activeId }) {
            collection.profiles[index].token = token
        } else if var profile = collection.activeProfile {
            profile.token = token
            collection.upsert(profile)
        } else {
            let profile = TokenProfile(name: defaultProfileName(for: environment), token: token)
            collection.upsert(profile)
        }
        persist(collection, environment: environment)
        return collection
    }

    @discardableResult
    func setActive(id: UUID, environment: LoginEnvironment) -> TokenProfileCollection {
        var collection = load(environment: environment)
        guard collection.profiles.contains(where: { $0.id == id }) else { return collection }
        collection.activeProfileId = id
        persist(collection, environment: environment)
        return collection
    }

    @discardableResult
    func rename(id: UUID, to name: String, environment: LoginEnvironment) -> TokenProfileCollection {
        var collection = load(environment: environment)
        collection.rename(id: id, to: name)
        persist(collection, environment: environment)
        return collection
    }

    @discardableResult
    func delete(id: UUID, environment: LoginEnvironment) -> TokenProfileCollection {
        var collection = load(environment: environment)
        collection.remove(id: id)
        persist(collection, environment: environment)
        return collection
    }

    /// Suggests a sensible name for the next "Add Account" profile, e.g.
    /// "Account 2" / "Account 3" so the user doesn't have to type one.
    func suggestedName(for environment: LoginEnvironment) -> String {
        let collection = load(environment: environment)
        let next = collection.profiles.count + 1
        return "Account \(next)"
    }

    // MARK: - Persistence helpers

    private func persist(_ collection: TokenProfileCollection, environment: LoginEnvironment) {
        let key = profilesKey(for: environment)
        if let data = try? JSONEncoder().encode(collection) {
            KeychainWrapper.global.set(data, forKey: key, withAccessibility: .afterFirstUnlock)
        }

        // Mirror the active profile's token to the legacy single-token
        // keychain entry so the widget extension and AppIntents continue
        // to read the right value without any further changes.
        let legacyKey = legacyKey(for: environment)
        if let active = collection.activeProfile,
           let encoded = try? JSONEncoder().encode(active.token) {
            KeychainWrapper.global.set(encoded, forKey: legacyKey, withAccessibility: .afterFirstUnlock)
        } else {
            KeychainWrapper.global.removeObject(forKey: legacyKey, withAccessibility: .afterFirstUnlock)
        }
    }

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

    private func legacyToken(for environment: LoginEnvironment) -> Token? {
        let key = legacyKey(for: environment)
        guard let data = KeychainWrapper.global.data(forKey: key, withAccessibility: .afterFirstUnlock) else {
            return nil
        }
        return try? JSONDecoder().decode(Token.self, from: data)
    }
}
