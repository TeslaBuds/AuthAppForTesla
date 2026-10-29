//
//  LicenseEntry.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI
import TeslaAuthKit

struct LicenseViewEntry: View {
    let component: OpenSourceComponent

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(component.name)
                        .font(.headline)
                    Text("by \(component.author)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let link = component.link {
                    Link(destination: link) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.title3)
                            .foregroundStyle(Color("TeslaRed"))
                    }
                }
            }

            DisclosureGroup("License", isExpanded: $isExpanded) {
                Text(component.licence)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, AppSpacing.xs)
            }
            .font(.subheadline)
            .tint(Color("TeslaRed"))
        }
        .padding(AppSpacing.cardInner)
    }
}

#Preview {
    LicenseViewEntry(component: .swiftKeychainWrapper)
}
