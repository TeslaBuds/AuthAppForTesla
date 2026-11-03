import Foundation
import Security
import Testing
@testable import TeslaAuthKit

@Suite("Device-bound token storage")
struct DeviceTokenStorageTests {
    @Test("A synchronized profile cannot authorize this device")
    func syncedProfileRequiresLogin() async throws {
        let keychain = SyntheticTokenKeychain()
        let profile = Self.profile("old-shared-grant")
        keychain.seedSynced(
            try JSONEncoder().encode(TokenProfileCollection(profiles: [profile])),
            for: kTokenV3Profiles
        )
        let store = TokenProfileStore(storage: TokenProfileStore.productionStorage(keychain: keychain))
        #expect(await store.load(environment: .owner).profiles.isEmpty)
        let transport = ScriptedTransport { _ in .rejected(reason: "synthetic refusal") }
        let refresh = TokenRefreshService(
            store: store, transport: transport, ledger: InMemoryRejectionLedger(), maxAttempts: 1
        )
        let outcome = await refresh.refresh(environment: .owner, forceRefresh: true)
        #expect(outcome.token == nil)
        #expect(transport.posted.isEmpty)
        #expect(keychain.deviceValues.isEmpty)
        #expect(keychain.syncedWriteCount == 0)
    }

    @Test("A synchronized legacy token is never adopted or mirrored")
    func syncedLegacyRequiresLogin() async throws {
        let keychain = SyntheticTokenKeychain()
        keychain.seedSynced(try JSONEncoder().encode(Self.profile("legacy-grant").token), for: kTokenV4)
        let store = TokenProfileStore(storage: TokenProfileStore.productionStorage(keychain: keychain))
        #expect(await store.load(environment: .fleet).profiles.isEmpty)
        #expect(keychain.deviceValues.isEmpty)
        #expect(keychain.syncedWriteCount == 0)
    }

    @Test("New authorization and its active mirror stay on this device")
    func freshAuthorizationIsDeviceOnly() async throws {
        let keychain = SyntheticTokenKeychain()
        let store = TokenProfileStore(storage: TokenProfileStore.productionStorage(keychain: keychain))
        let profile = Self.profile("fresh-device-grant")
        try await store.upsert(profile: profile, environment: .owner, makeActive: true)
        #expect(keychain.syncedWriteCount == 0)
        #expect(keychain.deviceValues[kTokenV3Profiles] != nil)
        #expect(keychain.deviceValues[kTokenV3] != nil)
        #expect(await store.load(environment: .owner).activeProfile?.id == profile.id)
    }

    @Test("Two device authorizations remain independent")
    func separateDeviceCredentials() async throws {
        let phone = SyntheticTokenKeychain()
        let mac = SyntheticTokenKeychain()
        let phoneStore = TokenProfileStore(storage: TokenProfileStore.productionStorage(keychain: phone))
        let macStore = TokenProfileStore(storage: TokenProfileStore.productionStorage(keychain: mac))
        let phoneProfile = Self.profile("phone-grant")
        let macProfile = Self.profile("mac-grant")
        try await phoneStore.upsert(profile: phoneProfile, environment: .fleet, makeActive: true)
        try await macStore.upsert(profile: macProfile, environment: .fleet, makeActive: true)
        let phoneToken = await phoneStore.load(environment: .fleet).activeProfile?.token
        let macToken = await macStore.load(environment: .fleet).activeProfile?.token
        #expect(phoneToken?.refresh_token == phoneProfile.token.refresh_token)
        #expect(macToken?.refresh_token == macProfile.token.refresh_token)
        #expect(phone.deviceValues[kTokenV4] != mac.deviceValues[kTokenV4])
        #expect(phone.syncedWriteCount + mac.syncedWriteCount == 0)
    }

    @Test("Read-only intent lookup uses the same device boundary")
    func readOnlyLookupDoesNotAdoptSync() throws {
        let keychain = SyntheticTokenKeychain()
        let profile = Self.profile("old-status-grant")
        keychain.seedSynced(
            try JSONEncoder().encode(TokenProfileCollection(profiles: [profile])),
            for: kTokenV3Profiles
        )
        keychain.seedSynced(try JSONEncoder().encode(profile.token), for: kTokenV3)
        let storage = TokenProfileStore.productionStorage(keychain: keychain)
        #expect(StoredTokenReader.profiles(for: .owner, storage: storage).profiles.isEmpty)
        #expect(keychain.syncedWriteCount == 0)
        #expect(keychain.deviceValues.isEmpty)
    }

    @Test("The production query explicitly excludes synchronization and device transfer")
    func exactStorageClass() throws {
        let storage = try #require(TokenProfileStore.productionStorage() as? KeychainSyncedItemStorage)
        let keychain = storage.keychain
        #expect(!keychain.iCloudSync)
        #expect(keychain.serviceName == "AuthForTesla")
        #expect(keychain.accessGroup == "group.global")
        let query = keychain.setupKeychainQueryDictionary(
            forKey: kTokenV3Profiles, withAccessibility: storage.accessibility
        )
        #expect(query[kSecAttrSynchronizable as String] as? Bool == false)
        #expect(
            query[kSecAttrAccessible as String] as? String == kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String
        )
    }

    @Test("Local sign-out leaves the old synchronized grant untouched")
    func deleteDoesNotRetireAnotherDevicesGrant() async throws {
        let keychain = SyntheticTokenKeychain()
        let legacy = try JSONEncoder().encode(Self.profile("legacy-other-device").token)
        keychain.seedSynced(legacy, for: kTokenV4)
        let store = TokenProfileStore(storage: TokenProfileStore.productionStorage(keychain: keychain))
        let local = Self.profile("current-device")
        try await store.upsert(profile: local, environment: .fleet, makeActive: true)
        try await store.delete(id: local.id, environment: .fleet)
        try await store.clearLegacyMirror(environment: .fleet)
        #expect(await store.load(environment: .fleet).profiles.isEmpty)
        #expect(keychain.syncedValues[kTokenV4] == legacy)
        #expect(keychain.syncedWriteCount == 0)
    }

    private static func profile(_ sentinel: String) -> TokenProfile {
        TokenProfile(
            name: "Synthetic account",
            token: Token(
                access_token: "synthetic-access-\(sentinel)", token_type: "bearer", expires_in: 3600,
                refresh_token: "synthetic-refresh-\(sentinel)", expires_at: nil, region: .global
            )
        )
    }
}
