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

public enum StoredTokenReader {
    /// The local profiles for an API. A legacy entry is accepted only in
    /// the same device-only storage class; synchronized grants never fall
    /// through into status intents or account queries.
    public static func profiles(for environment: LoginEnvironment) -> TokenProfileCollection {
        profiles(for: environment, storage: TokenProfileStore.productionStorage())
    }

    static func profiles(
        for environment: LoginEnvironment, storage: any SyncedItemStorage
    ) -> TokenProfileCollection {
        let decoder = JSONDecoder()
        switch storage.read(profilesKey(for: environment)) {
        case .found(let data):
            return (try? decoder.decode(TokenProfileCollection.self, from: data)) ?? TokenProfileCollection()
        case .failed:
            return TokenProfileCollection()
        case .notFound:
            guard case .found(let data) = storage.read(legacyKey(for: environment)),
                  let token = try? decoder.decode(Token.self, from: data) else {
                return TokenProfileCollection()
            }
            return TokenProfileCollection(profiles: [TokenProfile(name: "", token: token)])
        }
    }

    /// The profile a token-reporting intent should look at: the one the
    /// person picked, or the active one when they left it empty.
    public static func profile(in collection: TokenProfileCollection, id: UUID?) -> TokenProfile? {
        guard let id else { return collection.activeProfile }
        return collection.profiles.first { $0.id == id }
    }

    /// When a token's access token expires. Uses the expiry recorded when
    /// the token was stored, falling back to the access token's own `exp`
    /// claim for tokens stored without one.
    public static func expirationDate(of token: Token) -> Date? {
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
