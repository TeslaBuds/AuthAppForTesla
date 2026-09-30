#!/bin/bash
# Captures the native Mac app's App Store screenshots through its own
# capture harness (MacCaptureHarness, DEBUG builds only): each scenario is
# one launch that seeds the screenshot fixture in the model (never the
# keychain), photographs the presented window and quits.
#
#   capture-mac.sh <path to Debug "Auth for Tesla.app"> [out dir]
#
# Run it in the GUI session:
#   /Users/kh/Source/GitHub/DRSFramer/scripts/gui-run.sh /bin/bash "$PWD/Screenshots/capture-mac.sh" <app> <out>
set -u
APP="${1:?path to Auth for Tesla.app}"
OUT="${2:-$(cd "$(dirname "$0")" && pwd)/output/Mac}"
mkdir -p "$OUT"
status=0
while read -r name scenario; do
    [ -z "$name" ] && continue
    # Every argument starts with "-": AppKit opens a bare one as a document.
    rm -f "$OUT/.log"
    /usr/bin/open -n --stderr "$OUT/.log" "$APP" --args -enable-testing -"$scenario" -mac-capture "$name"
    for _ in $(seq 1 60); do grep -q 'CAPTURES DONE' "$OUT/.log" 2>/dev/null && break; sleep 1; done
    sleep 1
    log=$(cat "$OUT/.log" 2>/dev/null)
    path=$(printf '%s\n' "$log" | awk -v n="$name" '$1=="CAPTURE" && $2==n {print $3}' | tail -1)
    if [ -n "$path" ] && [ -f "$path" ]; then
        # Another app's container is protected (App Data): if this shell may
        # not read it, the path is printed for a shell that may.
        if cp "$path" "$OUT/$name.png" 2>/dev/null; then echo "captured $name"; else echo "captured $name at $path"; fi
    else
        echo "FAILED $name"; printf '%s\n' "$log" | tail -5; status=1
    fi
done <<'LIST'
01_owners_home screenshot-owners-home
02_owners_login screenshot-owners-login
03_test_token screenshot-test-token
04_jwt_inspector screenshot-jwt-inspector
05_snippet_exporter screenshot-snippet-exporter
06_multi_account screenshot-multi-account
07_fleet_home screenshot-fleet-home
08_about screenshot-about
LIST
exit $status
