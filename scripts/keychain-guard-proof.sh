#!/bin/bash
# The real-keychain, multi-launch proof of the sync-wipe guard (#44).
# Each phase is a separate launch of the signed Mac app hosting
# KeychainGuardProofTests. Run it in the GUI security session:
#
#   /Users/kh/Source/GitHub/DRSFramer/scripts/gui-run.sh /bin/bash \
#       "$PWD/scripts/keychain-guard-proof.sh" <derived-data-dir> <log-dir>
#
# Exit 0 only if every phase passed.
set -u
REPO="$(cd "$(dirname "$0")/.." && pwd)"
DD="${1:?derived data dir}"
LOGS="${2:?log dir}"
mkdir -p "$LOGS"
cd "$REPO"

run() {
    local phase="$1" dd="$2"; shift 2
    TEST_RUNNER_AFT_PROOF_PHASE="$phase" TEST_RUNNER_AFT_PROOF_FINGERPRINT="${FINGERPRINT:-}" \
    /usr/bin/xcodebuild test -project AuthAppForTesla.xcodeproj -scheme AuthAppForTeslaMac \
        -destination 'platform=macOS' -derivedDataPath "$dd" -allowProvisioningUpdates \
        -only-testing:AuthAppForTeslaMacTests/KeychainGuardProofTests "$@" > "$LOGS/$phase.log" 2>&1
    local rc=$?
    grep -h 'AFT-PROOF' "$LOGS/$phase.log" | sort -u
    grep -hE '✔ Test run|✘|Test run with' "$LOGS/$phase.log" | tail -3
    echo "PHASE $phase rc=$rc"
    return $rc
}

run seed "$DD" || exit 1
run reread "$DD" || exit 1
FINGERPRINT=$(grep -h 'AFT-PROOF \[reread\] FINGERPRINT' "$LOGS/reread.log" | head -1 | awk '{print $NF}')
echo "launch 2 fingerprint: $FINGERPRINT"
[ -n "$FINGERPRINT" ] || { echo "no fingerprint"; exit 1; }
run noaccess "$DD-noaccess" CODE_SIGN_ENTITLEMENTS="$REPO/scripts/fixtures/NoKeychainGroup.entitlements" || exit 1
run verify "$DD" || exit 1
run cleanup "$DD" || exit 1
echo "KEYCHAIN GUARD PROOF PASSED"
