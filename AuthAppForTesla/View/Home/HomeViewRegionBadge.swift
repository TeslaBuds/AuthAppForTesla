//
//  HomeViewRegionBadge.swift
//  AuthAppForTesla
//
//  Compact pill that shows which Tesla region a stored token resolves
//  to. Combines the explicitly chosen region with the Fleet refresh
//  token prefix so the UI can be specific (e.g. "Europe") rather than
//  just "Global".
//

import SwiftUI

struct HomeViewRegionBadge: View {
    let token: Token
    let environment: LoginEnvironment

    var body: some View {
        let detected = token.detectedRegion(for: environment)
        Label("Region: \(detected.displayName)", systemImage: "globe")
            .font(.footnote)
            .foregroundStyle(.secondary)
            .accessibilityIdentifier("regionBadge")
    }
}

#Preview {
    HomeViewRegionBadge(
        token: Token(
            access_token: "x",
            token_type: "bearer",
            expires_in: 0,
            refresh_token: "eu_refreshtoken",
            expires_at: nil,
            region: nil
        ),
        environment: .fleet
    )
}
