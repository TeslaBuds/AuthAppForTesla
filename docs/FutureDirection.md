# Future direction

A grab-bag of feature ideas that would make Auth for Tesla more useful and more
attractive without changing what the app fundamentally is: a small, focused
helper for getting and managing Tesla API tokens.

These ideas are deliberately scoped so that none of them require shipping
features that depend on the unofficial / undocumented Owners API. Anything that
goes beyond pure OAuth handling is built on top of the officially supported
Fleet API.

## Guiding principles

- Stay a token tool first. Every new feature should make tokens easier to
  obtain, inspect, refresh, or use — not turn the app into a Tesla client.
- Prefer features that work for Fleet API developers, since that is the
  audience we can serve openly.
- Lean into App Intents, Shortcuts, and Widgets so the app keeps composing
  well with the rest of iOS.

## Things that fit naturally with what's already there

### 1. Token health & lifecycle dashboard
- Visual countdown to access-token expiry, refresh-token age, last-refresh
  timestamp.
- "Auto-refresh in background" toggle using `BGAppRefreshTask`, so widgets and
  Shortcuts always have a fresh token available.
- Local notification when a refresh fails — so users find out *before* their
  automation breaks at 2am.

### 2. "Test your token" panel for the Fleet API
A few read-only calls so the user can prove the token actually works
end-to-end. None of this requires storing vehicle data — it is purely
diagnostic:
- `GET /api/1/users/me` — show name, email, profile image.
- `GET /api/1/products` — list vehicles, energy sites, wall connectors.
- `GET /api/1/vehicles/{id}` — show VIN, display name, state
  (online/asleep/offline).
- A "scopes granted" inspector that decodes the JWT and shows which Fleet API
  scopes the token actually has. Tesla's scope errors are notoriously cryptic,
  so this alone is worth shipping.

### 3. Partner-account / app registration helpers
The hardest part of Fleet API onboarding is the developer setup, not the OAuth
flow. The app could be the friendliest tool for that:
- A guided "register your domain" checklist with deep-links to dev.tesla.com.
- Public-key generation plus a one-tap copy of the
  `/.well-known/appspecific/com.tesla.3p.public-key.pem` URL it should be
  hosted at.
- A "register partner account" button that calls
  `POST /api/1/partner_accounts` with the user's domain.
- A validator that fetches the user's public-key URL and confirms it is
  reachable and correctly formatted.

### 4. Virtual Key / vehicle command pairing helper
Generate the `tesla.com/_ak/<your-domain>` deep link as a QR code so the user
can pair their car with their app from another device. Extremely useful for
any developer building vehicle-command features on the Fleet API.

### 5. Telemetry / streaming config helper
The Fleet Telemetry config endpoint
(`POST /api/1/vehicles/fleet_telemetry_config`) is painful to call by hand. A
simple form to build the JSON config + push it, plus a viewer for the current
config, would be a genuinely unique offering.

## Developer quality-of-life features

### 6. Richer App Intents / Shortcuts
The app already exposes token-getter intents. Add intents for:
- "Get vehicle list" — returns an `AppEntity` per vehicle.
- "Wake vehicle" / "Get vehicle state" — both handy in Shortcuts pipelines.
- "Decode current token" — returns scopes, expiry, region as structured
  output other shortcuts can branch on.

### 7. cURL / code-snippet exporter
For any token, a "Copy as cURL", "Copy as HTTPie", "Copy as Swift
URLRequest", "Copy as Python requests" button, with a placeholder endpoint.
Cheap to build, instantly useful to anyone testing the API.

### 8. Multiple accounts / token profiles
Today there is one token slot per environment. Letting users name and switch
between several profiles (e.g. "personal", "work fleet", "test partner")
makes the app much more useful for anyone running more than one Tesla
developer app.

### 9. Region auto-detect & manual override UI
The audience-URL building in `AuthController+FleetAPI.swift` is region
sensitive and currently inferred from the auth code prefix. A clear UI
showing the detected region with a manual override would prevent a whole
class of "why doesn't it work in EU/CN" support issues.

### 10. JWT inspector tab
Paste any token (or use the stored one) and see pretty-printed claims, an
expiry countdown, and a signature-verified badge. Simple, but a tool every
Tesla-API developer reaches for jwt.io to do today.

## Polish / monetization angles

### 11. Lock Screen / StandBy widgets
The app already ships widgets. Add a Lock Screen accessory showing "Token
expires in 14m" with a tap-to-refresh deep link. Pairs nicely with StandBy
on iPhone.

### 12. Apple Watch companion
A single screen: token status + "refresh now". Small scope, large
"this is thoughtful" factor.

### 13. Tip-jar tier with "Pro" features
Multi-account profiles, snippet exporters, and the partner-account helpers
are good candidates for "thank-you-for-tipping" unlocks without feeling
exploitative.

## If we had to pick three first

1. **#2 — Test-your-token panel.** Immediately validates that the user's
   setup actually works and surfaces granted scopes, which is the single
   biggest source of confusion for Fleet API developers.
2. **#3 / #4 / #5 — Partner-account, virtual-key, and telemetry helpers.**
   Together, these turn the app from "OAuth helper" into "the tool I open
   whenever I'm working with Tesla's Fleet API."
3. **#7 — cURL / snippet exporter.** Tiny implementation, very high
   perceived value, and a great hook for the App Store description.
