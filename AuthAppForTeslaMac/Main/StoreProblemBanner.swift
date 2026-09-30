//
//  StoreProblemBanner.swift
//  AuthAppForTesla
//
//  Shown when this device cannot read the synced token items, so it looks
//  signed out. Says so, and that nothing will be changed: the sync-wipe
//  guard refuses every write until the items can be read (#44).
//

import SwiftUI
import TeslaAuthKit

struct StoreProblemBanner: View {
    let problem: TokenStoreError

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("Your synced tokens can't be read on this device")
                    .font(.subheadline)
                    .bold()
                Text("Nothing will be changed here, so your tokens on your other devices stay as they are.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: "exclamationmark.lock.fill")
                .foregroundStyle(.orange)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.md)
        .glassEffect(.regular, in: .rect(cornerRadius: AppCornerRadius.card))
        .padding(AppSpacing.md)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    StoreProblemBanner(problem: .unreadable(-34018))
}
