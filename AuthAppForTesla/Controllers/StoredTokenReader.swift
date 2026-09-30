//
//  StoredTokenReader.swift
//  AuthAppForTesla
//
//  A strictly read-only view of the stored token profiles, for App
//  Intents that only report on a token. Unlike `TokenProfileStore.load`,
//  it never migrates the legacy single-token entry or writes anything
//  back to the keychain, and it never refreshes a token.
//

import Foundation

enum StoredTokenReader {
    /// The stored profiles for an API, exactly as they are in the
    /// keychain. A legacy single-token entry that has not been migrated
    /// yet is reported as one unnamed, active profile — without
    /// migrating it.
    static func profiles(for environment: LoginEnvironment) -> TokenProfileCollection {
        let decoder = JSONDecoder()
        if let data = KeychainWrapper.global.data(forKey: profilesKey(for: environment), withAccessibility: .afterFirstUnlock),
           let collection = try? decoder.decode(TokenProfileCollection.self, from: data) {
            return collection
        }
        if let data = KeychainWrapper.global.data(forKey: legacyKey(for: environment), withAccessibility: .afterFirstUnlock),
           let token = try? decoder.decode(Token.self, from: data) {
            return TokenProfileCollection(profiles: [TokenProfile(name: "", token: token)])
        }
        return TokenProfileCollection()
    }

    /// The profile a token-reporting intent should look at: the one the
    /// person picked, or the active one when they left it empty.
    static func profile(in collection: TokenProfileCollection, id: UUID?) -> TokenProfile? {
        guard let id else { return collection.activeProfile }
        return collection.profiles.first { $0.id == id }
    }

    /// When a token's access token expires. Uses the expiry recorded when
    /// the token was stored, falling back to the access token's own `exp`
    /// claim for tokens stored without one.
    static func expirationDate(of token: Token) -> Date? {
        token.expires_at ?? JWTDecoder.decode(token.access_token)?.expiresAt
    }

    private static func profilesKey(for environment: LoginEnvironment) -> String {
        switch environment {
        case .owner: kTokenV3Profiles
        case .fleet: kTokenV4Profiles
        }
    }

    private static func legacyKey(for environment: LoginEnvironment) -> String {
        switch environment {
        case .owner: kTokenV3
        case .fleet: kTokenV4
        }
    }
}
