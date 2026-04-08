//
//  TokenRegionDetection.swift
//  AuthAppForTesla
//
//  Pure helpers for figuring out which region a token belongs to. We
//  combine the region the user picked at sign-in time with hints from
//  the refresh token (Tesla encodes a 2-letter region prefix into Fleet
//  refresh tokens such as "eu", "na", "cn"), so the UI can show the
//  user what we'll actually talk to.
//

import Foundation

/// A best-guess region for a stored token. The `code` is the granular
/// 2-letter Fleet region prefix (e.g. "eu", "na") when known; the `region`
/// is the coarse global/china classification used to pick the auth host.
struct DetectedTokenRegion: Equatable {
    let region: TokenRegion
    let code: String?

    var displayName: String {
        if let code, let pretty = Self.fleetRegionDisplayNames[code.lowercased()] {
            return pretty
        }
        return region.rawValue.capitalized
    }

    private static let fleetRegionDisplayNames: [String: String] = [
        "na": "North America",
        "eu": "Europe",
        "ap": "Asia Pacific",
        "me": "Middle East",
        "cn": "China"
    ]
}

extension Token {
    /// Resolves the region for a token, preferring the explicit region
    /// stored at sign-in time and falling back to the Fleet refresh-token
    /// prefix when no region was recorded.
    func detectedRegion(for environment: LoginEnvironment) -> DetectedTokenRegion {
        switch environment {
        case .owner:
            return DetectedTokenRegion(region: region ?? .global, code: nil)
        case .fleet:
            let code = fleetRefreshTokenRegion?.lowercased()
            let resolved: TokenRegion
            if let region {
                resolved = region
            } else if code == "cn" {
                resolved = .china
            } else {
                resolved = .global
            }
            return DetectedTokenRegion(region: resolved, code: code)
        }
    }
}
