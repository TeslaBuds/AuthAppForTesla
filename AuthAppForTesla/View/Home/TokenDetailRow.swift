//
//  TokenDetailRow.swift
//  AuthAppForTesla
//
//  Compact label/value row used by the access- and refresh-token
//  detail panels in the Home view. Inspired by `LabeledContent` from
//  a Form, but rendered on a plain VStack so it sits cleanly inside
//  the home glass card without dragging in Form's grouped chrome.
//

import SwiftUI

/// A two-column row: secondary-styled label on the leading edge,
/// primary-styled value on the trailing edge. Long values wrap and
/// stay right-aligned so multi-line values still read as "the value
/// for this key".
struct TokenDetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
            Text(label)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(minWidth: 80, alignment: .leading)
            Text(value)
                .font(.footnote)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

/// A row for repeating values (audiences, scopes). Renders the label
/// on the leading edge with the count, then a vertically-stacked list
/// of the values on the trailing edge — one per line, right-aligned,
/// monospaced so URLs / scope identifiers line up.
struct TokenDetailList: View {
    let label: String
    let values: [String]

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: AppSpacing.sm) {
            Text("\(label) (\(values.count))")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(minWidth: 80, alignment: .leading)
            VStack(alignment: .trailing, spacing: 2) {
                ForEach(values, id: \.self) { value in
                    Text(value)
                        .font(.footnote.monospaced())
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.trailing)
                        .textSelection(.enabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }
}

#Preview {
    VStack(spacing: AppSpacing.xs) {
        TokenDetailRow(label: "Region", value: "NA")
        TokenDetailRow(label: "Issued", value: "Jan 1, 2025 at 1:00 PM")
        TokenDetailRow(label: "Issuer", value: "https://auth.tesla.com/oauth2/v3")
        TokenDetailList(
            label: "Scopes",
            values: ["openid", "email", "offline_access", "vehicle_device_data"]
        )
    }
    .padding()
}
