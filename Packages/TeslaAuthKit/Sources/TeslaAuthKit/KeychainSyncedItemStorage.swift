import Foundation
import Security

/// Status-preserving Keychain adapter. The legacy type name and default
/// accessibility remain for compatibility with the #44 guard fixtures.
/// Production token callers use `TokenProfileStore.productionStorage`,
/// which selects an exact device-only namespace and accessibility.
public struct KeychainSyncedItemStorage: SyncedItemStorage, @unchecked Sendable {
    public let keychain: KeychainWrapper

    let accessibility: KeychainItemAccessibility

    public init(
        keychain: KeychainWrapper,
        accessibility: KeychainItemAccessibility = .afterFirstUnlock
    ) {
        self.keychain = keychain
        self.accessibility = accessibility
    }

    public func read(_ key: String) -> KeychainReadResult {
        keychain.readResult(forKey: key, withAccessibility: accessibility)
    }

    public func add(_ data: Data, forKey key: String) -> OSStatus {
        keychain.addOnly(data, forKey: key, withAccessibility: accessibility)
    }

    public func replace(_ data: Data, forKey key: String) -> OSStatus {
        keychain.updateOnly(data, forKey: key, withAccessibility: accessibility)
    }

    public func remove(_ key: String) -> OSStatus {
        keychain.removeReturningStatus(forKey: key, withAccessibility: accessibility)
    }
}
