// swift-tools-version: 6.2
import PackageDescription

/// The model layer both Auth for Tesla apps share (AuthAppForTesla#44):
/// tokens and profiles, the synced keychain store and its sync-wipe
/// guard, JWT decoding, PKCE, region detection and snippet generation.
/// No UI. `swift test` runs the suite on the Mac.
let package = Package(
    name: "TeslaAuthKit",
    platforms: [.iOS(.v26), .macOS(.v26)],
    products: [
        .library(name: "TeslaAuthKit", targets: ["TeslaAuthKit"]),
    ],
    targets: [
        .target(name: "TeslaAuthKit", swiftSettings: [.swiftLanguageMode(.v5)]),
        .testTarget(name: "TeslaAuthKitTests", dependencies: ["TeslaAuthKit"], swiftSettings: [.swiftLanguageMode(.v5)]),
    ]
)
