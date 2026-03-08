//
//  AppVersionLabel.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 08/03/2026.
//

import SwiftUI

/// Displays the app version and build number in a consistent format across all views.
struct AppVersionLabel: View {
    private let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    private let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""

    var body: some View {
        Text("v. \(version) build \(build)")
            .font(.caption)
            .multilineTextAlignment(.center)
            .foregroundStyle(.secondary)
    }
}

#Preview {
    AppVersionLabel()
}
