#!/bin/bash
# SwiftLint build phase — Auth for Tesla's own (TeslaBuds/AuthAppForTesla#66).
#
# Every app and extension target runs this as its first build phase, so a new
# violation fails the build in Xcode, xcodebuild, the Xcode MCP and archives.
#
# It lints with Auth's own .swiftlint.yml (SwiftLint's defaults plus the global
# Swift/SwiftUI house rules, strict: true) against .swiftlint-baseline.json.
# It deliberately does NOT run RumskrotShared's BrandKit guardrails
# (guardrails-build-phase.sh / brand-rules.py): Auth for Tesla is open source
# and not a BrandKit app (Kim, 15 Oct 2026: "It's also not brandkit at all,
# since it's open source."), and RumskrotShared excludes it from the brand
# baselines (524ec29, f5996b9). Running them anyway is what broke main (#66).
#
# The target sets ENABLE_USER_SCRIPT_SANDBOXING = NO: under the sandbox
# SwiftLint cannot enumerate the tree.

set -uo pipefail

cd "${SRCROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}" || exit 1

# Xcode's build-phase PATH does not include Homebrew.
SWIFTLINT=""
for candidate in "$(command -v swiftlint 2>/dev/null || true)" /opt/homebrew/bin/swiftlint /usr/local/bin/swiftlint; do
    if [ -n "$candidate" ] && [ -x "$candidate" ]; then SWIFTLINT="$candidate"; break; fi
done
if [ -z "$SWIFTLINT" ]; then
    echo "error: SwiftLint not found. Install it with \`brew install swiftlint\` — a build that did not lint is never green."
    exit 1
fi

BASELINE_ARGS=()
[ -f .swiftlint-baseline.json ] && BASELINE_ARGS=(--baseline .swiftlint-baseline.json)
"$SWIFTLINT" lint --quiet --config .swiftlint.yml "${BASELINE_ARGS[@]+"${BASELINE_ARGS[@]}"}"
