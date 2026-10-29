//
//  OwnersAuthInFlight.swift
//  AuthAppForTesla
//

import Foundation
import TeslaAuthKit

/// Snapshot of an Owners API OAuth flow that's currently between
/// "build authorize URL" and "exchange code for token". Identifiable
/// so it can drive `.sheet(item:)`; a stable id (UUID per flow) keeps
/// SwiftUI from recreating the auth sheet's content view if the model
/// republishes for unrelated reasons.
///
/// Carries a `TeslaAuthSession` (long-lived `WKWebView` + nav
/// delegate) so the in-flight auth WebView survives SwiftUI parent
/// view rebuilds — without it the user loses anything they've typed
/// when iOS reactivates the app from a password-manager hop.
struct OwnersAuthInFlight: Identifiable, Equatable {
    let id = UUID()
    var url: URL
    var codeVerifier: String
    /// The random `state` sent; the redirect must carry it back (#51).
    var state: String
    var region: TokenRegion
    var addAsNewProfile: Bool
    let session: TeslaAuthSession

    static func == (lhs: OwnersAuthInFlight, rhs: OwnersAuthInFlight) -> Bool {
        lhs.id == rhs.id
    }
}
