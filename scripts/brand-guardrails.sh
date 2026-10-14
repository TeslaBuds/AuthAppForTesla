#!/bin/bash
# BrandKit guardrails build phase. THIN WRAPPER — managed by RumskrotShared;
# do not add logic here (WAFT#218, DRSFramer#69).
#
# Every app and extension target runs this file as its first build phase. It
# finds RumskrotShared/scripts/guardrails-build-phase.sh — ONE copy for every
# consumer — and execs it. The house rules are enforced by the BUILD: a new
# violation fails it in Xcode, xcodebuild, the Xcode MCP and archives.
#
# Which RumskrotShared, first that carries the script:
#   1. $RUMSKROT_SHARED_CHECKOUT, if set;
#   2. the build's OWN pinned SwiftPM checkout
#      (<DerivedData>/SourcePackages/checkouts/RumskrotShared), so the rules
#      move with this commit's pin;
#   3. a pin older than the guardrails (v2026.10.14.9) falls back to the
#      checkout on disk — ../RumskrotShared, the main worktree's
#      ../RumskrotShared, /Users/kh/Source/GitHub/RumskrotShared — and says so.
#      Installing the phase must not force a pin bump (that would change what
#      the app draws); the next ordinary bump moves the app onto step 2.
#   Nothing found is an error: a build that did not lint is never green.

# Refresh it from RumskrotShared/scripts/consumer-guardrails-wrapper.sh
# (install-guardrails.py does).

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export SRCROOT="${SRCROOT:-$REPO_ROOT}"
SCRIPT=scripts/guardrails-build-phase.sh

candidates=()
[ -n "${RUMSKROT_SHARED_CHECKOUT:-}" ] && candidates+=("$RUMSKROT_SHARED_CHECKOUT")
if [ -n "${BUILD_DIR:-}" ]; then
    dir="$BUILD_DIR"
    while [ "$dir" != "/" ] && [ -n "$dir" ]; do
        if [ -d "$dir/SourcePackages/checkouts/RumskrotShared" ]; then
            candidates+=("$dir/SourcePackages/checkouts/RumskrotShared")
            break
        fi
        dir="$(dirname "$dir")"
    done
fi
pinned_count=${#candidates[@]}
candidates+=("$REPO_ROOT/../RumskrotShared")
common_dir="$(git -C "$REPO_ROOT" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || echo "")"
[ -n "$common_dir" ] && candidates+=("$(dirname "$common_dir")/../RumskrotShared")
candidates+=("/Users/kh/Source/GitHub/RumskrotShared")

i=0
for candidate in "${candidates[@]}"; do
    if [ -f "$candidate/$SCRIPT" ]; then
        if [ $i -ge $pinned_count ] && [ $pinned_count -gt 0 ]; then
            echo "note: BrandKit guardrails: the pinned RumskrotShared predates the guardrails; running them from $(cd "$candidate" && pwd) until the next pin bump."
        fi
        exec /bin/bash "$candidate/$SCRIPT" "$@"
    fi
    i=$((i + 1))
done
echo "error: BrandKit guardrails: cannot find RumskrotShared/$SCRIPT (tried: ${candidates[*]}) — a build that did not lint is never green."
exit 1
