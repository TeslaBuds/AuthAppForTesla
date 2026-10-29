//
//  FleetAuthInFlight.swift
//  AuthAppForTesla
//

import Foundation
import TeslaAuthKit

/// Snapshot of a Fleet API OAuth flow in flight. Carries the
/// developer-supplied client credentials so the code exchange can
/// complete with the same values the URL was built from, even if the
/// user has navigated away from the login view since. Also carries
/// the `TeslaAuthSession` (see `OwnersAuthInFlight` for rationale).
struct FleetAuthInFlight: Identifiable, Equatable {
    let id = UUID()
    var url: URL
    /// The random `state` sent; the redirect must carry it back (#51).
    var state: String
    var region: TokenRegion
    var clientId: String
    var clientSecret: String
    var redirectUri: String
    var addAsNewProfile: Bool
    let session: TeslaAuthSession

    static func == (lhs: FleetAuthInFlight, rhs: FleetAuthInFlight) -> Bool {
        lhs.id == rhs.id
    }
}
