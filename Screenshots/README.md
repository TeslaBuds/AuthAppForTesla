# Screenshots

Source of truth for App Store marketing screenshots and metadata. The
**framed posters** that get uploaded to App Store Connect come from a
separate tool called **DRSFramer**, which lives outside this repo.

## Layout

```
Screenshots/
├── appstore.json          # everything ASC needs (app, version, iap,
│                          # review, screenshots, capture config)
├── capture.sh             # thin wrapper → DRSFramer/scripts/capture.sh
├── README.md              # this file
├── output/                # raw captures from the simulator (gitignored)
│   ├── iPhone 17 Pro Max/
│   └── iPad Pro 13-inch (M5)/
└── Rendered/              # framed posters produced by DRSFramer
    ├── iPhone_*.png
    └── iPad_*.png
```

## Pipeline

```
ScreenshotTests.swift ─▶ xcresult ─▶ xcresulttool export
       (XCUITest)         bundle      attachments
                                        │
                                        ▼
                              Screenshots/output/<device>/*.png
                                        │
                                        ▼
                                appstore.json + raw PNGs
                                        │
                                        ▼
                                    DRSFramer
                                  (frame + push)
                                        │
                                        ▼
                            Screenshots/Rendered/*.png
                                        │
                                        ▼
                              App Store Connect
```

## Running captures

```bash
# Full suite, all devices
./Screenshots/capture.sh

# Single device
./Screenshots/capture.sh "iPhone 17 Pro Max"

# Single test method on a single device
./Screenshots/capture.sh "iPhone 17 Pro Max" testCapture04_JWTInspector
```

The wrapper delegates to `DRSFramer/scripts/capture.sh`, which:

1. Reads the `capture` section of `appstore.json` (scheme, UI test target,
   simulators).
2. Creates a fresh temporary clone of each simulator so parallel runs from
   different repos can't collide and every capture starts from a clean
   state.
3. Boots the sim, waits for SpringBoard, sets `9:41` / full bars / charged.
4. Runs `xcodebuild build-for-testing` then `test-without-building` with
   up to 3 retries on the well-known iPad xctrunner preflight flake.
5. Pulls the PNGs out of the `.xcresult` via `xcrun xcresulttool export
   attachments` and stages them into `Screenshots/output/<device>/`.
6. Tears down the temporary simulators on exit (including Ctrl-C).

## Adding a new screenshot

1. **Add a test method** in `Auth for Tesla UI Tests/ScreenshotTests.swift`:
   ```swift
   @MainActor
   func testCapture09_NewScene() throws {
       launch(["enable-testing", "screenshot-new-scene"])
       takeScreenshot(named: "09_new_scene")
   }
   ```

2. **Wire the launch arg** in `AuthAppForTeslaApp.applyScreenshotScenario`
   so the app sets up the right state and lands on the right screen.

3. **Add a slot** in `Screenshots/appstore.json` (one entry per platform):
   ```json
   {
     "key": "09_new_scene",
     "headline": "Headline Text",
     "subtitle": "Optional subtitle",
     "platform": "iPhone",
     "sortOrder": 8
   }
   ```

4. **Run** `./Screenshots/capture.sh` to regenerate.

## Frame and push

After capture:

```bash
# Frame locally to preview before uploading
swift run --package-path /Users/kh/Source/GitHub/DRSFramer drsframer frame Screenshots
open Screenshots/Rendered

# Dry-run push to App Store Connect
swift run --package-path /Users/kh/Source/GitHub/DRSFramer drsframer push Screenshots/appstore.json --dry-run

# Real push (full)
swift run --package-path /Users/kh/Source/GitHub/DRSFramer drsframer push Screenshots/appstore.json

# Push only one section
swift run --package-path /Users/kh/Source/GitHub/DRSFramer drsframer push Screenshots/appstore.json --only version
```

`--only` accepts: `app`, `version`, `screenshots`, `review`, `iap`.

## Devices

| Platform | Simulator              | Required by ASC |
|----------|------------------------|-----------------|
| iPhone   | iPhone 17 Pro Max      | Yes             |
| iPad     | iPad Pro 13-inch (M5)  | Yes             |

Only the largest device per platform is required — smaller sizes are
auto-scaled by App Store Connect.
