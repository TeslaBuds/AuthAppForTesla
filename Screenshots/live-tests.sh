#!/usr/bin/env bash
#
# live-tests.sh — Run the LiveAuthTests against a fresh simulator clone.
#
# These tests perform the real Tesla OAuth flow against a throwaway
# demo account (credentials hardcoded in LiveAuthTests.swift) and walk
# through the entire app: sign in, refresh tokens, run real Test Token
# API calls, inspect a JWT, generate a snippet, and log out.
#
# Each run creates a temporary cloned simulator so:
#   - Every run starts from a clean keychain state.
#   - Multiple runs from different repos can't collide.
# The clone is deleted on exit (including Ctrl-C / errors).
#
# Usage
# -----
#
#   ./Screenshots/live-tests.sh
#       Run on the default iPhone simulator.
#
#   ./Screenshots/live-tests.sh "iPad Pro 13-inch (M5)"
#       Run on a specific iOS simulator.
#
#   ./Screenshots/live-tests.sh "iPhone 17 Pro Max" testLive_01_FreshSignIn
#       Run a single test method on a specific simulator.
#
#   ./Screenshots/live-tests.sh Mac
#       Run on Mac Catalyst — no clone, runs against your live Mac.
#
# Prerequisites
# -------------
# - Xcode with command-line tools.
# - The simulator listed below installed.
# - Network access to auth.tesla.com.
#

set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="AuthAppForTesla"
DEFAULT_DEVICE="iPhone 17 Pro Max"

DEVICE="${1:-$DEFAULT_DEVICE}"
SINGLE_TEST="${2:-}"

XCODEPROJ="$PROJECT_DIR/AuthAppForTesla.xcodeproj"
RESULT_BUNDLE="$PROJECT_DIR/Screenshots/.live-test-result"
LOG_PATH="$RESULT_BUNDLE.log"

UI_TEST_TARGET="Auth for Tesla UI Tests/LiveAuthTests"
if [ -n "$SINGLE_TEST" ]; then
    UI_TEST_TARGET="$UI_TEST_TARGET/$SINGLE_TEST"
fi

CLONED_UDIDS=()

cleanup_clones() {
    if [ ${#CLONED_UDIDS[@]} -eq 0 ]; then
        return
    fi
    echo ""
    echo "Cleaning up temporary simulators…"
    for udid in "${CLONED_UDIDS[@]}"; do
        xcrun simctl shutdown "$udid" 2>/dev/null || true
        xcrun simctl delete "$udid" 2>/dev/null || true
    done
    echo "  deleted ${#CLONED_UDIDS[@]} temporary simulator(s)"
}
trap cleanup_clones EXIT

create_temp_simulator() {
    local source_name="$1"
    local sim_info
    sim_info=$(xcrun simctl list devices available -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data.get('devices', {}).items():
    for device in devices:
        if device['name'] == '$source_name' and device['isAvailable']:
            print(device['deviceTypeIdentifier'] + '|||' + runtime)
            sys.exit(0)
sys.exit(1)
" 2>/dev/null) || {
        echo "Error: Source simulator '$source_name' not found." >&2
        return 1
    }

    local device_type="${sim_info%%|||*}"
    local runtime="${sim_info##*|||}"
    local temp_name="LiveTest_${source_name// /_}_$$"

    xcrun simctl create "$temp_name" "$device_type" "$runtime" 2>/dev/null
}

boot_simulator() {
    local udid="$1"
    xcrun simctl boot "$udid" 2>/dev/null || true
    xcrun simctl bootstatus "$udid" -b 2>/dev/null || true
    xcrun simctl spawn "$udid" defaults write -g AppleLocale -string en_US 2>/dev/null || true
    xcrun simctl spawn "$udid" defaults write -g AppleLanguages -array en 2>/dev/null || true

    # Disable the host's hardware keyboard connection so the software
    # keyboard appears in the simulator. XCUITest's typeText() routes
    # via the on-screen keyboard, so without this nothing reaches the
    # WKWebView text fields on Tesla's auth page.
    defaults write com.apple.iphonesimulator ConnectHardwareKeyboard -bool false 2>/dev/null || true

    # Wait for SpringBoard to actually be ready for app installs.
    # bootstatus reports "Finished" before SpringBoard fully settles,
    # causing "SBMainWorkspace Busy" preflight failures on fresh sims.
    local waited=0
    while [ "$waited" -lt 30 ]; do
        if xcrun simctl launch "$udid" com.apple.Preferences 2>/dev/null; then
            xcrun simctl terminate "$udid" com.apple.Preferences 2>/dev/null || true
            break
        fi
        sleep 2
        waited=$((waited + 2))
    done
}

run_on_mac() {
    echo "Running LiveAuthTests on My Mac (Mac Catalyst) — uses real keychain"
    rm -rf "$RESULT_BUNDLE" "${RESULT_BUNDLE}.xcresult" "$LOG_PATH"

    # The TEST_RUNNER_ prefix tells xcodebuild to forward the variable
    # into the test runner process; the test then reads it without the
    # prefix via ProcessInfo.processInfo.environment["AFT_LIVE_TESTS"].
    xcodebuild test \
        -project "$XCODEPROJ" \
        -scheme "$SCHEME" \
        -destination 'platform=macOS,variant=Mac Catalyst' \
        -resultBundlePath "$RESULT_BUNDLE" \
        -only-testing:"$UI_TEST_TARGET" \
        -allowProvisioningUpdates \
        TEST_RUNNER_AFT_LIVE_TESTS=1 \
        > "$LOG_PATH" 2>&1
    local exit_code=$?
    tail -50 "$LOG_PATH"
    if [ "$exit_code" -ne 0 ]; then
        echo ""
        echo "Live test run failed. Full log: $LOG_PATH"
    fi
    exit $exit_code
}

run_on_simulator() {
    local source_name="$1"

    echo "Cloning '$source_name' for a clean live test run…"
    local udid
    udid=$(create_temp_simulator "$source_name") || exit 1
    CLONED_UDIDS+=("$udid")
    echo "  clone UDID: ${udid:0:8}…"

    boot_simulator "$udid"

    local destination="platform=iOS Simulator,id=${udid}"
    rm -rf "$RESULT_BUNDLE" "${RESULT_BUNDLE}.xcresult" "$LOG_PATH"

    echo "  building test bundles…"
    # The KeychainWrapper uses accessGroup="group.global", which is
    # only honoured when the app is signed with the matching
    # entitlement. CODE_SIGN_IDENTITY="-" / CODE_SIGNING_ALLOWED="NO"
    # would strip entitlements and silently break every keychain write
    # — so we sign with the dev team via -allowProvisioningUpdates.
    if ! xcodebuild build-for-testing \
            -project "$XCODEPROJ" \
            -scheme "$SCHEME" \
            -destination "$destination" \
            -only-testing:"$UI_TEST_TARGET" \
            -allowProvisioningUpdates \
            > "$LOG_PATH" 2>&1; then
        echo "Error: build-for-testing failed."
        tail -30 "$LOG_PATH"
        exit 1
    fi

    # The xctrunner preflight is flaky on fresh sim clones — first
    # attempt often fails with "SBMainWorkspace Busy". Retry up to
    # 3 times, restarting SpringBoard between attempts.
    local exit_code=1
    local attempt
    for attempt in 1 2 3; do
        if [ "$attempt" -gt 1 ]; then
            echo "  retrying (attempt $attempt/3)…"
            xcrun simctl terminate "$udid" "dk.kimhansen.Auth-for-Tesla-UI-Tests.xctrunner" 2>/dev/null || true
            xcrun simctl terminate "$udid" "dk.kimhansen.AuthAppForTesla" 2>/dev/null || true
            xcrun simctl shutdown "$udid" 2>/dev/null || true
            sleep 3
            xcrun simctl boot "$udid" 2>/dev/null || true
            xcrun simctl bootstatus "$udid" -b 2>/dev/null || true
            sleep 4
            xcrun simctl spawn "$udid" launchctl kickstart -k system/com.apple.SpringBoard 2>/dev/null || true
            sleep 2
            rm -rf "$RESULT_BUNDLE" "${RESULT_BUNDLE}.xcresult"
        fi

        echo "Running LiveAuthTests on $source_name (attempt $attempt/3)"

        xcodebuild test-without-building \
            -project "$XCODEPROJ" \
            -scheme "$SCHEME" \
            -destination "$destination" \
            -resultBundlePath "$RESULT_BUNDLE" \
            -only-testing:"$UI_TEST_TARGET" \
            -allowProvisioningUpdates \
            > "$LOG_PATH" 2>&1
        exit_code=$?

        # If the test runner actually launched (regardless of pass/fail
        # of the test logic itself), we're done — no point retrying a
        # legitimate test failure.
        if ! grep -q "SBMainWorkspace Busy\|Failed to install or launch the test runner" "$LOG_PATH"; then
            break
        fi
    done

    tail -60 "$LOG_PATH"

    if [ "$exit_code" -ne 0 ]; then
        echo ""
        echo "Live test run failed. Full log: $LOG_PATH"
        echo ""
        echo "On failure, the LiveTestLog OAuth trace is attached to"
        echo "${RESULT_BUNDLE}.xcresult as DEBUG_z_oauth_log. Extract it with:"
        echo "  xcrun xcresulttool get test-results activities \\"
        echo "    --test-id 'LiveAuthTests/<test name>()' \\"
        echo "    --path ${RESULT_BUNDLE}.xcresult"
    fi
    exit $exit_code
}

if [[ "$DEVICE" == "Mac" || "$DEVICE" == "My Mac" ]]; then
    run_on_mac
else
    run_on_simulator "$DEVICE"
fi
