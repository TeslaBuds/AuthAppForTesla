# App Store Connect — Marketing Content

## App Store Description

Need to generate modern, secure Tesla API authentication tokens? Auth for Tesla has you covered.

Built on the proven authentication foundation of Watch for Tesla, this app lets you log in to your Tesla account once and instantly get the OAuth tokens you need — for Shortcuts, third-party apps, automation tools, and more.

**What you get:**
- Owners API (v3) tokens — the standard token used by most Tesla-compatible apps and Shortcuts
- Fleet API (v4) tokens — for developers building on Tesla's modern Fleet API
- Tap any token to copy it to your clipboard, ready to paste into any app or Shortcut
- Built-in Siri and Shortcuts actions so automations can fetch and refresh your tokens on demand — no manual steps needed

**Completely private by design.**
Your Tesla username and password are entered directly in a secure in-app browser — they never pass through this app or any server run by the developer. Your tokens are stored encrypted in your iCloud Keychain and sync privately across your own devices.

**Open source.**
Every line of code is publicly available and auditable at:
https://github.com/TeslaBuds/AuthAppForTesla

Disclaimer: This app is not affiliated with or endorsed by Tesla, Inc. Use at your own risk. No guarantee of proper function is given. You are solely responsible for any changes to your vehicle caused by the use of this app.

Made in Denmark 🇩🇰


---

## Marketing Text (170 chars max)

Securely generate Tesla OAuth tokens for Shortcuts, automation, and third-party apps. Owners API and Fleet API supported. Open source. Private by design.


---

## What's New (Version 3.0)

Version 3.0 is a complete overhaul — a brand new design built for iOS 26 with Liquid Glass, smarter automation, and a more welcoming experience from the first launch.

**New in 3.0:**
- Redesigned for iOS 26 with the Liquid Glass visual style
- Welcome flow — a quick introduction on first launch explaining tokens, privacy, and Shortcuts
- Error notifications — auth failures and refresh errors now appear as clear, dismissible banners instead of failing silently
- Siri & Shortcuts — all four actions (Get / Refresh for both Owners and Fleet API) now appear automatically in the Shortcuts app and are available to Siri without any setup
- Shortcuts guide — a new card in the About tab lists every available action and links directly to the Shortcuts app
- Clipboard privacy — copied tokens now automatically expire from the clipboard after one hour
- Widget-ready — the app now prepares token expiry data for an upcoming Home Screen widget
- Stability fixes — resolved a black screen during login, fixed token not being captured after sign-in, and corrected the Fleet API token exchange

---

## Privacy Manifest Notes

See `PrivacyInfo.xcprivacy` in the app bundle for the full machine-readable manifest.
Key declarations:
- No data collected or transmitted to the developer
- Network access is to Tesla's own OAuth endpoints only
- Keychain usage: access tokens and refresh tokens, stored with iCloud sync in the user's own account
- UserDefaults (App Group): token expiry timestamps shared with the widget extension only
- No tracking, no analytics, no third-party SDKs
