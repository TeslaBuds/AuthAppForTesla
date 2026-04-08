# Future direction

A grab-bag of feature ideas that would make Auth for Tesla more useful and
more attractive without changing what the app fundamentally is: a small,
focused helper for getting and managing Tesla API tokens.

These ideas are deliberately scoped so that none of them require shipping
features that depend on the unofficial / undocumented Owners API. Anything
that goes beyond pure OAuth handling is built on top of the officially
supported Fleet API.

Items implemented in 3.0.1 are crossed out and grouped at the bottom so
the live list stays useful for planning the next round.

## Guiding principles

- Stay a token tool first. Every new feature should make tokens easier to
  obtain, inspect, refresh, or use — not turn the app into a Tesla client.
- Prefer features that work for Fleet API developers, since that is the
  audience we can serve openly.
- Lean into App Intents, Shortcuts, and Widgets so the app keeps composing
  well with the rest of iOS.
- Treat Mac Catalyst as a first-class platform, not a side effect of iPad.

## What we should pick up next

The shortlist for the next release, in order of "biggest payoff for the
audience that's already buying the app."

### A. Partner-account / app registration helpers
The hardest part of Fleet API onboarding is the developer setup, not the
OAuth flow. The app could be the friendliest tool for that:
- A guided "register your domain" checklist with deep-links to dev.tesla.com.
- Public-key generation plus a one-tap copy of the
  `/.well-known/appspecific/com.tesla.3p.public-key.pem` URL it should be
  hosted at.
- A "register partner account" button that calls
  `POST /api/1/partner_accounts` with the user's domain.
- A validator that fetches the user's public-key URL and confirms it is
  reachable and correctly formatted.

This is the highest-value feature we haven't built. With the Tools tab in
place, we have a natural home for it.

### B. Virtual Key / vehicle command pairing helper
Generate the `tesla.com/_ak/<your-domain>` deep link as a QR code so the
user can pair their car with their app from another device. Extremely
useful for any developer building vehicle-command features on the Fleet
API. Pairs naturally with the partner-account helpers above.

### C. Telemetry / streaming config helper
The Fleet Telemetry config endpoint
(`POST /api/1/vehicles/fleet_telemetry_config`) is painful to call by
hand. A simple form to build the JSON config + push it, plus a viewer
for the current config, would be a genuinely unique offering. The Test
Token panel already has the plumbing for authenticated Fleet API calls.

### D. Richer App Intents / Shortcuts
The app already exposes token-getter intents. Add intents for:
- "Get vehicle list" — returns an `AppEntity` per vehicle.
- "Wake vehicle" / "Get vehicle state" — both handy in Shortcuts pipelines.
- "Decode current token" — returns scopes, expiry, region as structured
  output other shortcuts can branch on. The JWT decoder logic from the
  Tools tab already exists; this is mostly an `AppIntent` wrapper.

### E. Background refresh + failure notifications
The token health dashboard surfaces expiry, but doesn't *do* anything
about it. Add a `BGAppRefreshTask` that proactively refreshes any active
profile whose token is within ~15 minutes of expiring, and a local
notification when a refresh fails so the user finds out *before* their
2am Shortcut breaks.

### F. Lock Screen / StandBy widgets
The app already ships widgets. Add a Lock Screen accessory showing "Token
expires in 14m" with a tap-to-refresh deep link. Pairs nicely with
StandBy on iPhone, and would be a small but very visible upgrade.

### G. Apple Watch companion
A single screen: token status + "refresh now". Small scope, large "this
is thoughtful" factor. The token health view already renders well at
that size — porting it to a watch app should be mostly project setup.

## Mac-specific ideas (new since 3.0.1)

We made Mac Catalyst a real target in 3.0.1 (window sizing, ⌘R,
multi-account popover positioning). A few obvious follow-ups now that
Mac is a first-class citizen:

### M1. Re-evaluate "Optimized for Mac" sizing
The app currently uses iPad-scaled sizing on Mac (`MACCATALYST_OPTIMIZE_FOR_MAC_FAMILY` is off), so everything renders at ~0.77x. Switching to Optimized for Mac would give native AppKit-like metrics and slightly more refined typography. Risk: some custom layouts might need tweaking, especially the IconBackgroundView pattern. Worth a controlled experiment.

### M2. Menu bar app variant
A `MenuBarExtra` scene that lives in the menu bar, shows the active
profile's expiry countdown, and offers Refresh / Switch Profile / Open
Tools as one-click items. This is the most "Mac-native" thing we could
ship and would be very useful for anyone running token-driven scripts
on a Mac.

### M3. Drag-out tokens
Mac Catalyst supports drag-out from views. Letting users drag a token
chip out of the home view onto a Terminal window or text editor would
make the snippet exporter even more direct.

### M4. Re-enable the Friends-of-the-App grid on Catalyst
Currently `#if !targetEnvironment(macCatalyst)` because
`SKStoreProductViewController` doesn't behave on Catalyst. **Skipped per
user direction** — the store view still doesn't render correctly on Mac.
Leaving the grid hidden on Catalyst.

## Polish / monetization angles

### Tip-jar tier with "Pro" features
Multi-account profiles, snippet exporters, and the partner-account
helpers are good candidates for "thank-you-for-tipping" unlocks without
feeling exploitative. Worth revisiting once partner-account helpers (A)
are in.

## Implemented in 3.0.1

The 3.0.1 release picked up most of the Tools-tab and developer
quality-of-life ideas from the original list. Keeping them here as a
record so future planning doesn't accidentally re-propose them.

- ✅ **Token health & lifecycle dashboard** — every home view now shows
  a colored countdown to expiry, the inferred last-refresh time, the
  active profile name, and a region badge. Background refresh + failure
  notifications are still pending (see E above).
- ✅ **Test your token panel** — Tools → Test Your Token runs read-only
  Owners or Fleet API calls (`users/me`, `vehicles`, `products`) and
  shows results inline, plus a local scopes inspector built into the
  JWT inspector.
- ✅ **cURL / code-snippet exporter** — Tools → Snippet Exporter
  generates ready-to-paste cURL, HTTPie, Swift `URLRequest`, and Python
  `requests` code for the active token.
- ✅ **Multiple accounts / token profiles** — named profiles per API
  with one-tap switching, rename, add another, and delete; backed by a
  new `TokenProfileStore` actor with lazy migration of any existing
  single-token install.
- ✅ **Region auto-detect & manual override UI** — `Token.detectedRegion`
  combines the explicit stored region with the Fleet refresh-token
  prefix (`na`, `eu`, `ap`, `me`, `cn`) and shows it as a badge in the
  home header.
- ✅ **JWT Inspector tab** — Tools → JWT Inspector decodes any pasted
  token (or one of the stored ones) into header, payload, scopes,
  expiry, and a Valid/Expired status badge.
