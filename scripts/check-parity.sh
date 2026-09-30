#!/bin/bash
# Keeps the iOS and Mac apps honest (AuthAppForTesla#44, after
# RumskrotIssues #231): every App Intent and App Shortcuts provider has a
# row in docs/feature-parity.json, and every row's code is compiled exactly
# where the row says. Fix drift in the code or the manifest, never here.
# Install as a pre-commit hook with:  ln -s ../../scripts/check-parity.sh .git/hooks/pre-commit
cd "$(git rev-parse --show-toplevel 2>/dev/null || dirname "$0"/..)" || exit 2
exec /usr/bin/python3 - <<'PY'
import json, re, pathlib, sys
m = json.load(open("docs/feature-parity.json"))
def sources(roots):
    text = {}
    for root in roots:
        for p in pathlib.Path(root).rglob("*.swift"):
            text[str(p)] = p.read_text(errors="ignore")
    return text
decl = re.compile(r"\b(?:struct|class|enum|actor)\s+(\w+)\s*(?::\s*([^{]*))?\{")
errors = []
rows = {r["code"]: r for r in m["features"]}
for platform, roots in m["platforms"].items():
    src = sources(roots)
    declared = set()
    for path, text in src.items():
        for name, conformances in decl.findall(text):
            declared.add(name)
            conf = conformances or ""
            if re.search(r"\b(AppIntent|AppShortcutsProvider)\b", conf) and name not in rows:
                errors.append(f"{platform}: {name} ({path}) is an intent/provider with no row in docs/feature-parity.json")
    for row in m["features"]:
        state = row.get(platform, "")
        compiled = row["code"] in declared
        if state == "shipped" and not compiled:
            errors.append(f"{platform}: {row['id']} is shipped but {row['code']} is not compiled there")
        elif state.startswith(("planned", "exempt")) and compiled:
            errors.append(f"{platform}: {row['id']} is '{state}' but {row['code']} is compiled there")
        elif not state.startswith(("shipped", "planned #", "exempt: ")):
            errors.append(f"{platform}: {row['id']} has no valid state ('{state}')")
for e in errors: print("PARITY:", e)
print("parity: OK" if not errors else f"parity: {len(errors)} problem(s)")
sys.exit(1 if errors else 0)
PY
