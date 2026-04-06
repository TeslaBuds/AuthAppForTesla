#!/usr/bin/env bash
#
# capture.sh - Capture App Store screenshots using XCUITest
#
# Usage:
#   ./capture.sh                              # Capture all devices
#   ./capture.sh "iPhone 17 Pro Max"          # Capture a single iOS device
#   ./capture.sh "iPad Pro 13-inch (M5)"      # Capture iPad only
#
# Prerequisites:
#   - Simulators for each target device must be installed
#   - xcresulttool ships with Xcode -- no extra brew install needed
#
set -uo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME_IOS="AuthAppForTesla"
RESULT_BUNDLE="$PROJECT_DIR/Screenshots/.xcresult"
OUTPUT_DIR="$PROJECT_DIR/Screenshots/output"

IPHONE_SIMULATORS=(
    "iPhone 17 Pro Max"
)
IPAD_SIMULATORS=(
    "iPad Pro 13-inch (M5)"
)

HAS_FAILURES=0
SINGLE_DEVICE="${1:-}"

if ! xcrun --find xcresulttool &>/dev/null; then
    echo "Error: xcresulttool not found (should ship with Xcode)."
    exit 1
fi

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

get_simulator_udid() {
    local name="$1"
    xcrun simctl list devices available -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
for devices in data.get('devices', {}).values():
    for device in devices:
        if device['name'] == '$name' and device['isAvailable']:
            print(device['udid'])
            sys.exit(0)
sys.exit(1)
" 2>/dev/null
}

boot_simulator() {
    local udid="$1"
    xcrun simctl boot "$udid" 2>/dev/null || true
    xcrun simctl bootstatus "$udid" -b 2>/dev/null || true
    xcrun simctl spawn "$udid" defaults write -g AppleLocale -string en_US 2>/dev/null || true
    xcrun simctl spawn "$udid" defaults write -g AppleLanguages -array en 2>/dev/null || true
}

run_tests_on_device() {
    local simulator_name="$1"
    local udid
    udid=$(get_simulator_udid "$simulator_name") || {
        echo "Warning: Simulator '$simulator_name' not found. Skipping."
        return 0
    }

    local destination="platform=iOS Simulator,id=${udid}"
    local result_path="${RESULT_BUNDLE}_${simulator_name// /_}"
    local device_output="$OUTPUT_DIR/$simulator_name"
    local log_path="${result_path}.log"

    echo "Capturing iOS screenshots on $simulator_name"
    rm -rf "$result_path" "${result_path}.xcresult" "$log_path"

    boot_simulator "$udid"
    echo "  building test bundles..."
    if ! xcodebuild build-for-testing \
            -project "$PROJECT_DIR/AuthAppForTesla.xcodeproj" \
            -scheme "$SCHEME_IOS" \
            -destination "$destination" \
            -only-testing:"Auth for Tesla UI Tests/ScreenshotTests" \
            CODE_SIGN_IDENTITY="-" \
            CODE_SIGNING_ALLOWED="NO" \
            > "$log_path" 2>&1; then
        echo "Error: build-for-testing failed on $simulator_name"
        tail -30 "$log_path"
        HAS_FAILURES=1
        return
    fi

    local attempt
    local has_attachments=0
    for attempt in 1 2 3; do
        if [ "$attempt" -gt 1 ]; then
            echo "  no screenshots produced -- recovering sim and retrying ($attempt/3)"
            xcrun simctl terminate "$udid" dk.kimhansen.AuthAppForTesla.uitests.xctrunner 2>/dev/null || true
            xcrun simctl terminate "$udid" dk.kimhansen.AuthAppForTesla 2>/dev/null || true

            if [ "$attempt" -eq 3 ]; then
                xcrun simctl shutdown all 2>/dev/null || true
                sleep 3
                xcrun simctl erase "$udid" 2>/dev/null || true
                sleep 3
            else
                xcrun simctl shutdown "$udid" 2>/dev/null || true
                sleep 3
            fi

            xcrun simctl boot "$udid" 2>/dev/null || true
            xcrun simctl bootstatus "$udid" -b 2>/dev/null || true
            sleep 4
            xcrun simctl spawn "$udid" launchctl kickstart -k system/com.apple.SpringBoard 2>/dev/null || true
            sleep 2
            override_status_bar "$udid"
            rm -rf "$result_path" "${result_path}.xcresult"
        else
            override_status_bar "$udid"
        fi

        xcodebuild test-without-building \
            -project "$PROJECT_DIR/AuthAppForTesla.xcodeproj" \
            -scheme "$SCHEME_IOS" \
            -destination "$destination" \
            -resultBundlePath "$result_path" \
            -only-testing:"Auth for Tesla UI Tests/ScreenshotTests" \
            CODE_SIGN_IDENTITY="-" \
            CODE_SIGNING_ALLOWED="NO" \
            > "$log_path" 2>&1 || true
        tail -30 "$log_path"

        clear_status_bar "$udid"

        local probe_bundle=""
        if [ -d "${result_path}.xcresult" ]; then
            probe_bundle="${result_path}.xcresult"
        elif [ -d "$result_path" ]; then
            probe_bundle="$result_path"
        fi
        if [ -n "$probe_bundle" ]; then
            local probe_dir="${result_path}.probe"
            rm -rf "$probe_dir"
            mkdir -p "$probe_dir"
            xcrun xcresulttool export attachments \
                --path "$probe_bundle" \
                --output-path "$probe_dir" \
                >/dev/null 2>&1 || true
            if [ -f "$probe_dir/manifest.json" ]; then
                local png_count
                png_count=$(find "$probe_dir" -maxdepth 1 -name "*.png" | wc -l | tr -d ' ')
                if [ "$png_count" -gt 0 ]; then
                    has_attachments=1
                fi
            fi
            rm -rf "$probe_dir"
        fi

        if [ "$has_attachments" -eq 1 ]; then
            break
        fi
    done

    if [ "$has_attachments" -ne 1 ]; then
        echo "Warning: Screenshot tests produced no attachments on $simulator_name after 3 attempts"
        HAS_FAILURES=1
    fi

    local bundle_path
    if [ -d "${result_path}.xcresult" ]; then
        bundle_path="${result_path}.xcresult"
    elif [ -d "$result_path" ]; then
        bundle_path="$result_path"
    else
        echo "Error: No result bundle found for $simulator_name"
        HAS_FAILURES=1
        return
    fi

    local export_dir="${result_path}.export"
    rm -rf "$export_dir"
    mkdir -p "$export_dir"
    xcrun xcresulttool export attachments \
        --path "$bundle_path" \
        --output-path "$export_dir" \
        >/dev/null 2>&1 || true

    if [ ! -f "$export_dir/manifest.json" ]; then
        echo "Error: xcresulttool did not produce a manifest for $simulator_name"
        HAS_FAILURES=1
        rm -rf "$export_dir"
        return
    fi

    local staging_dir="${export_dir}.staged"
    rm -rf "$staging_dir"
    mkdir -p "$staging_dir"

    python3 - "$export_dir" "$staging_dir" <<'PY'
import json
import pathlib
import re
import shutil
import sys

export_dir = pathlib.Path(sys.argv[1])
staging_dir = pathlib.Path(sys.argv[2])

manifest = json.loads((export_dir / "manifest.json").read_text())
tail = re.compile(r"_\d+_[0-9A-Fa-f-]{36}\.png$")

for entry in manifest:
    for att in entry.get("attachments", []):
        exported = att.get("exportedFileName")
        suggested = att.get("suggestedHumanReadableName", "") or ""
        if not exported or not suggested.endswith(".png"):
            continue
        clean = tail.sub(".png", suggested)
        src = export_dir / exported
        if src.exists():
            shutil.copyfile(src, staging_dir / clean)
PY

    local staged_count
    staged_count=$(find "$staging_dir" -maxdepth 1 -name "*.png" | wc -l | tr -d ' ')
    if [ "$staged_count" -gt 0 ]; then
        rm -rf "$device_output"
        mkdir -p "$device_output"
        mv "$staging_dir"/*.png "$device_output/"
    else
        echo "Warning: no PNG attachments in $simulator_name xcresult -- keeping previous screenshots"
        HAS_FAILURES=1
    fi

    rm -rf "$export_dir" "$staging_dir"
}

echo "Capturing AuthAppForTesla screenshots"
if [ -z "$SINGLE_DEVICE" ]; then
    rm -rf "$OUTPUT_DIR"
fi
mkdir -p "$OUTPUT_DIR"

if [ -n "$SINGLE_DEVICE" ]; then
    run_tests_on_device "$SINGLE_DEVICE"
else
    for sim in "${IPHONE_SIMULATORS[@]}"; do
        run_tests_on_device "$sim"
    done

    for sim in "${IPAD_SIMULATORS[@]}"; do
        run_tests_on_device "$sim"
    done
fi

open "$OUTPUT_DIR"

if [ "$HAS_FAILURES" -ne 0 ]; then
    exit 1
fi
