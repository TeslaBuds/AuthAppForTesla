//
//  AboutViewShortcuts.swift
//  AuthAppForTesla
//

import AppIntents
import SwiftUI

/// A card in the About tab listing the available Siri Shortcuts/App Intents.
struct AboutViewShortcuts: View {
    private struct ShortcutItem: Identifiable {
        let id = UUID()
        let title: String
        let description: String
        let systemImage: String
    }

    private let items: [ShortcutItem] = [
        ShortcutItem(
            title: "Get Owners API Token",
            description: "Returns the current Owners API refresh and access tokens.",
            systemImage: "steeringwheel"
        ),
        ShortcutItem(
            title: "Get Fleet API Token",
            description: "Returns the current Fleet API refresh and access tokens.",
            systemImage: "car.2.fill"
        ),
        ShortcutItem(
            title: "Refresh Owners API Token",
            description: "Force-refreshes both Owners and Fleet API tokens.",
            systemImage: "arrow.clockwise"
        ),
        ShortcutItem(
            title: "Refresh Fleet API Token",
            description: "Force-refreshes both Owners and Fleet API tokens.",
            systemImage: "arrow.clockwise"
        )
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Siri & Shortcuts", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(Color("TeslaRed"))

            Text("Auth for Tesla includes the following built-in actions. Add them to the Shortcuts app or trigger them with Siri.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Divider()

            ForEach(items) { item in
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: item.systemImage)
                        .imageScale(.medium)
                        .foregroundStyle(Color("TeslaRed"))
                        .frame(width: 28)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.title)
                            .font(.subheadline)
                            .bold()
                        Text(item.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Button("Open Shortcuts App", systemImage: "arrow.up.right") {
                if let url = URL(string: "shortcuts://") {
                    UIApplication.shared.open(url)
                }
            }
            .font(.subheadline)
            .foregroundStyle(Color("TeslaRed"))
            .padding(.top, 4)
        }
        .padding()
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        .padding(.horizontal)
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            AboutViewShortcuts()
        }
    }
}
