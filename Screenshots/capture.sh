#!/usr/bin/env bash
#
# capture.sh — Capture App Store screenshots using XCUITest + xcparse
#
# Usage:
#   ./Screenshots/capture.sh                  # Run all devices
#   ./Screenshots/capture.sh "iPhone 16 Pro"  # Run a single device
#
# Prerequisites:
#   - Xcode command-line tools
#   - xcparse (brew install xcparse)
#
# What it does:
#   1. Overrides the simulator status bar to show the Apple-marketing look
#   2. Runs the screenshot test plan on each configured simulator
#   3. Extracts attachments from the .xcresult using xcparse
#   4. Organizes screenshots into Screenshots/output/<locale>/<device>/
#
set -uo pipefail

# ─── Configuration ───────────────────────────────────────────────────────────

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="AuthAppForTesla"
RESULT_BUNDLE="$PROJECT_DIR/Screenshots/.xcresult"
OUTPUT_DIR="$PROJECT_DIR/Screenshots/output"

# Mandatory App Store Connect devices (2026+)
# Only the largest per platform is required; smaller sizes auto-scale.
IPHONE_SIMULATORS=(
    "iPhone 17 Pro Max"
)
IPAD_SIMULATORS=(
    "iPad Pro 13-inch (M5)"
)
# Note: Apple Watch Ultra 3 is also mandatory but handled separately
# for apps that include a watchOS target.

# Track whether any device had failures
HAS_FAILURES=0

# Allow running a single device via argument
SINGLE_DEVICE="${1:-}"

# ─── Preflight checks ───────────────────────────────────────────────────────

if ! command -v xcparse &>/dev/null; then
    echo "Error: xcparse is not installed. Install via: brew install xcparse"
    exit 1
fi

if ! command -v xcrun &>/dev/null; then
    echo "Error: Xcode command-line tools are not installed."
    exit 1
fi

# ─── Helper functions ───────────────────────────────────────────────────────

override_status_bar() {
    local udid="$1"
    xcrun simctl status_bar "$udid" override \
        --time "9:41" \
        --operatorName " " \
        --cellularMode active \
        --cellularBar 4 \
        --wifiBars 3 \
        --batteryState charged \
        --batteryLevel 100
}

clear_status_bar() {
    local udid="$1"
    xcrun simctl status_bar "$udid" clear 2>/dev/null || true
}

get_or_create_simulator() {
    local name="$1"
    local udid

    # Try to find an existing simulator with this name
    udid=$(xcrun simctl list devices available -j \
        | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data.get('devices', {}).items():
    for d in devices:
        if d['name'] == '$name' and d['isAvailable']:
            print(d['udid'])
            sys.exit(0)
sys.exit(1)
" 2>/dev/null) || true

    if [ -z "$udid" ]; then
        echo "Warning: Simulator '$name' not found. Skipping." >&2
        return 1
    fi

    echo "$udid"
}

boot_simulator() {
    local udid="$1"
    local state
    state=$(xcrun simctl list devices -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
for runtime, devices in data.get('devices', {}).items():
    for d in devices:
        if d['udid'] == '$udid':
            print(d['state'])
            sys.exit(0)
")
    if [ "$state" != "Booted" ]; then
        xcrun simctl boot "$udid" 2>/dev/null || true
        # Give the simulator time to finish booting
        sleep 3
    fi
}

run_tests_on_device() {
    local simulator_name="$1"
    local platform="$2"
    local udid

    udid=$(get_or_create_simulator "$simulator_name") || return 0

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  📱 $simulator_name ($platform)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    echo "  Booting simulator..."
    boot_simulator "$udid"

    echo "  Overriding status bar..."
    override_status_bar "$udid"

    local destination="platform=${platform} Simulator,id=${udid}"
    local result_path="${RESULT_BUNDLE}_${simulator_name// /_}"

    # Remove previous result bundle for this device
    rm -rf "$result_path"

    echo "  Running screenshot tests..."
    local test_exit=0
    xcodebuild test \
        -project "$PROJECT_DIR/AuthAppForTesla.xcodeproj" \
        -scheme "$SCHEME" \
        -destination "$destination" \
        -resultBundlePath "$result_path" \
        -only-testing:"Auth for Tesla UI Tests/ScreenshotTests" \
        CODE_SIGN_IDENTITY="-" \
        CODE_SIGNING_ALLOWED="NO" \
        2>&1 | tail -20 || test_exit=$?

    if [ "$test_exit" -ne 0 ]; then
        echo "  Warning: Some tests failed (exit $test_exit). Extracting what we can."
        HAS_FAILURES=1
    fi

    echo "  Restoring status bar..."
    clear_status_bar "$udid"

    # Extract screenshots from the result bundle (even if some tests failed)
    local device_output="$OUTPUT_DIR/$simulator_name"
    rm -rf "$device_output"
    mkdir -p "$device_output"

    if [ -d "$result_path" ]; then
        echo "  Extracting screenshots with xcparse..."
        xcparse attachments "$result_path" "$device_output" \
            --uti public.png public.jpeg
        echo "  Done: $device_output"
    else
        echo "  Error: No result bundle found at $result_path"
        HAS_FAILURES=1
    fi
}

# ─── Main ────────────────────────────────────────────────────────────────────

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  App Store Screenshot Capture                              ║"
echo "║  Project: AuthAppForTesla                                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"

# Clean output directory
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"

if [ -n "$SINGLE_DEVICE" ]; then
    # Determine platform from device name
    if [[ "$SINGLE_DEVICE" == iPad* ]]; then
        run_tests_on_device "$SINGLE_DEVICE" "iOS"
    else
        run_tests_on_device "$SINGLE_DEVICE" "iOS"
    fi
else
    # Run all devices
    for sim in "${IPHONE_SIMULATORS[@]}"; do
        run_tests_on_device "$sim" "iOS"
    done

    for sim in "${IPAD_SIMULATORS[@]}"; do
        run_tests_on_device "$sim" "iOS"
    done
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  All screenshots captured!                                 ║"
echo "║  Output: Screenshots/output/                               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# List what was captured
echo "Captured files:"
find "$OUTPUT_DIR" -name "*.png" -o -name "*.jpg" | sort | while read -r f; do
    echo "  $(basename "$(dirname "$f")")/$(basename "$f")"
done

# Open the output folder in Finder for easy drag-and-drop to DRSFramer
open "$OUTPUT_DIR"

if [ "$HAS_FAILURES" -ne 0 ]; then
    echo "Warning: Some tests failed. Check output above for details."
    exit 1
fi
