# App Store Screenshot Automation

This project uses a pure native pipeline — **XCUITest + xcparse** — to capture and organize App Store screenshots. No Ruby, fastlane, or third-party gems required.

The raw screenshots are then fed into **DRSFramer** (a separate macOS app) along with a JSON manifest for final composition with device frames, text overlays, and branding.


## Architecture overview

```
ScreenshotTests.swift ──▶ .xcresult ──▶ xcparse ──▶ Screenshots/output/
       (XCUITest)           bundle        extract       raw PNGs
                                                          │
                                                          ▼
                                              screenshots.json + raw PNGs
                                                          │
                                                          ▼
                                                      DRSFramer
                                                  (macOS compositor)
                                                          │
                                                          ▼
                                              Final App Store images
```


## Prerequisites

- **Xcode** with command-line tools
- **xcparse**: `brew install xcparse`
- Simulators for target devices installed via Xcode


## File layout

```
<ProjectRoot>/
├── <UI Test Target>/
│   └── ScreenshotTests.swift        # XCUITest that captures each screen
├── Screenshots/
│   ├── capture.sh                   # Orchestration script
│   ├── screenshots.json             # DRSFramer manifest (JSON)
│   └── output/                      # (gitignored) raw captured PNGs
│       ├── iPhone 17 Pro Max/
│       │   ├── 01_screen_name.png
│       │   └── ...
│       └── iPad Pro 13-inch (M4)/
│           └── ...
```


## How to run

```bash
# Capture all devices
./Screenshots/capture.sh

# Capture a single device
./Screenshots/capture.sh "iPhone 17 Pro Max"
```

The script will:

1. Boot each simulator
2. Override the status bar to the Apple-marketing look (9:41, full bars, charged)
3. Run the screenshot tests via `xcodebuild test`
4. Extract attachments from the `.xcresult` using `xcparse`
5. Organize PNGs into `Screenshots/output/<device>/`
6. Restore the status bar


## How to add a new screenshot

1. **Add a test method** in `ScreenshotTests.swift`:
   ```swift
   @MainActor
   func testScreenshot05_NewScreen() throws {
       app.launch()
       // Navigate to the screen...
       takeScreenshot(named: "05_new_screen")
   }
   ```

2. **Add the entry** in `Screenshots/screenshots.json`:
   ```json
   {
     "key": "05_new_screen",
     "headline": "Headline Text",
     "subtitle": "Optional subtitle",
     "platform": "iPhone",
     "sortOrder": 4
   }
   ```
   Duplicate the entry with `"platform": "iPad"` if the app supports iPad.

3. **Run** `./Screenshots/capture.sh` to regenerate.


## JSON manifest contract (DRSFramer)

The `screenshots.json` file conforms to `ScreenshotManifest`:

```
ScreenshotManifest
├── bundleID: String           — app bundle identifier
└── screenshots: [ScreenshotMetadata]
    ├── key: String            — matches the filename (without extension)
    │                            from the xcparse output
    ├── headline: String       — primary text overlay
    ├── subtitle: String?      — secondary text overlay (optional)
    ├── platform: String       — "iPhone" | "iPad" | "appleWatch"
    └── sortOrder: Int         — App Store slot ordering
```

DRSFramer looks up branding (gradient, fonts, colors) by `bundleID` and composes each raw screenshot with device frames and text overlays into final App Store-ready images.


## Devices

Mandatory App Store Connect devices — only one per platform is required. Smaller sizes are auto-scaled by App Store Connect.

| Platform | Simulator | Required |
|----------|-----------|----------|
| iPhone | iPhone 17 Pro Max | Yes |
| iPad | iPad Pro 13-inch (M4) | Yes |
| Apple Watch | Apple Watch Ultra 3 | Yes (if app has watchOS target) |

The capture script only includes devices relevant to the app's supported platforms.


## Status bar override

The capture script uses `xcrun simctl status_bar` to set the marketing-clean status bar:

```bash
xcrun simctl status_bar booted override \
    --time 9:41 \
    --operatorName " " \
    --cellularMode active \
    --cellularBar 4 \
    --wifiBars 3 \
    --batteryState charged \
    --batteryLevel 100
```

This is restored after each capture run.
