import Foundation
import Security
import Synchronization
@testable import TeslaAuthKit

/// All overrides operate on locked synthetic data; none calls a Security API.
/// The inherited wrapper configuration is fixed by init and never mutated.
final class SyntheticTokenKeychain: KeychainWrapper, @unchecked Sendable {
    private struct State {
        var synced: [String: Data] = [:]
        var device: [String: Data] = [:]
        var syncedWrites = 0
    }
    private let state = Mutex(State())

    init() {
        super.init(serviceName: "SyntheticTokens", accessGroup: nil, iCloudSync: false)
    }

    var syncedValues: [String: Data] { state.withLock { $0.synced } }
    var deviceValues: [String: Data] { state.withLock { $0.device } }
    var syncedWriteCount: Int { state.withLock { $0.syncedWrites } }

    func seedSynced(_ value: Data, for key: String) { state.withLock { $0.synced[key] = value } }

    override func readResult(
        forKey key: String, withAccessibility accessibility: KeychainItemAccessibility? = nil
    ) -> KeychainReadResult {
        state.withLock {
            let values = accessibility == .afterFirstUnlockThisDeviceOnly ? $0.device : $0.synced
            return values[key].map(KeychainReadResult.found) ?? .notFound
        }
    }

    override func addOnly(
        _ value: Data, forKey key: String, withAccessibility accessibility: KeychainItemAccessibility
    ) -> OSStatus {
        state.withLock {
            if accessibility == .afterFirstUnlockThisDeviceOnly {
                guard $0.device[key] == nil else { return errSecDuplicateItem }
                $0.device[key] = value
            } else {
                $0.syncedWrites += 1
                guard $0.synced[key] == nil else { return errSecDuplicateItem }
                $0.synced[key] = value
            }
            return errSecSuccess
        }
    }

    override func updateOnly(
        _ value: Data, forKey key: String, withAccessibility accessibility: KeychainItemAccessibility
    ) -> OSStatus {
        state.withLock {
            if accessibility == .afterFirstUnlockThisDeviceOnly {
                guard $0.device[key] != nil else { return errSecItemNotFound }
                $0.device[key] = value
            } else {
                $0.syncedWrites += 1
                guard $0.synced[key] != nil else { return errSecItemNotFound }
                $0.synced[key] = value
            }
            return errSecSuccess
        }
    }

    override func removeReturningStatus(
        forKey key: String, withAccessibility accessibility: KeychainItemAccessibility
    ) -> OSStatus {
        state.withLock {
            if accessibility == .afterFirstUnlockThisDeviceOnly {
                return $0.device.removeValue(forKey: key) == nil ? errSecItemNotFound : errSecSuccess
            }
            $0.syncedWrites += 1
            return $0.synced.removeValue(forKey: key) == nil ? errSecItemNotFound : errSecSuccess
        }
    }
}
