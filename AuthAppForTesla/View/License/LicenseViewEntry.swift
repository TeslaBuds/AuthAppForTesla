//
//  LicenseEntry.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI

struct LicenseViewEntry: View {
    var author: String
    var name: String
    var link: String
    var license: String = ""

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.headline)
                    Text("by \(author)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if let url = URL(string: link) {
                    Link(destination: url) {
                        Image(systemName: "arrow.up.right.square")
                            .font(.title3)
                            .foregroundStyle(Color("TeslaRed"))
                    }
                }
            }

            if !license.isEmpty {
                DisclosureGroup("License", isExpanded: $isExpanded) {
                    Text(license)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 4)
                }
                .font(.subheadline)
                .tint(Color("TeslaRed"))
            }
        }
        .padding()
    }
}

#Preview {
    LicenseViewEntry(author: "Me", name: "Great Library", link: "https://github/superduper/library", license: "MIT License\n\nCopyright (c) 2020")
}
