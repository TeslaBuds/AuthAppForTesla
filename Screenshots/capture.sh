#!/usr/bin/env bash
#
# Thin wrapper — delegates to the shared capture script in DRSFramer.
# All configuration lives in appstore.json's "capture" section.
#
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DRSFRAMER_CAPTURE="/Users/kh/Source/GitHub/DRSFramer/scripts/capture.sh"

if [ ! -f "$DRSFRAMER_CAPTURE" ]; then
    echo "Error: Shared capture script not found at $DRSFRAMER_CAPTURE"
    echo "Clone or update the DRSFramer repo to get it."
    exit 1
fi

exec bash "$DRSFRAMER_CAPTURE" "$SCRIPT_DIR" "$@"
