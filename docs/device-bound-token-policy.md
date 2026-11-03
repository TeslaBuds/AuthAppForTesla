# Device-bound token grants (#71)

Owners and Fleet OAuth grants belong to the device that authorizes them. A refresh credential is never synchronized or adopted from another device's synchronized record. Each device must sign in separately.

## Storage boundary

`TokenProfileStore.productionStorage` selects the existing `AuthForTesla` service and `group.global` access group with an exact `kSecAttrSynchronizable = false` query and `AfterFirstUnlockThisDeviceOnly` accessibility. The access group still allows the existing app-family components on the same device; signing and entitlements do not change. The accessibility prevents an encrypted backup from cloning the grant onto a different device.

Both the profile collection and its active-token mirror use this policy. `StoredTokenReader` uses the same composition for read-only intent queries. `AuthController` obtains active tokens from its injected profile owner, without a second legacy synchronized fallback. Fleet partner configuration remains separate from account OAuth grants.

## Upgrade behavior

An installation with only the old synchronized token/profile items shows the existing sign-in screen. It does not decode, copy, refresh, overwrite or remove those items. A fresh sign-in creates a distinct non-synchronizable grant for this device. Signing out only removes this device's grant. The legacy names and profile Codable schema stay unchanged within the local namespace; saved shortcuts that target a new local profile continue using the existing intent types and profile IDs.

Old synchronized profiles cannot preserve their executable shortcut account binding automatically: that would silently adopt another device's grant. After device sign-in, the person selects the new local account in account-specific shortcuts. Active-account shortcuts can continue to omit the account parameter. Names/metadata are not extracted from the old secret-bearing records as part of this change. A future metadata-only synchronization format must contain no token fields.

Existing synchronized records are deliberately retained because other installed app versions may still use them. This patch does not claim to revoke a previously distributed credential or stop an old binary using it. A separate product rollout and retirement decision is needed for those copies. Do not silently delete the synchronized rows as a migration step.

## Verification

Package tests use a locked in-memory Keychain subclass; every storage primitive is overridden and no Security.framework operation or Tesla request is made. They cover rejecting synchronized collections and legacy mirrors, device-only fresh writes, independent device authorization, the exact Keychain query class, and read-only intent lookup. Existing unreadable/undecodable-write guards continue to apply.

The repo's real-Keychain multi-launch guard proof is not run in this session: the task forbids live Keychain access. Its historical fixture exercises synchronized storage and is not a substitute for a separately authorized device-only integration proof. Build/test results and this limitation accompany the remediation handoff.

The authentication policy of secret-returning App Intents and the DEBUG OAuth diagnostic export are separate #71 findings and are not changed by this patch.
