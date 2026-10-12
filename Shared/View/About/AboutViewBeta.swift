//
//  AboutViewBeta.swift
//  AuthAppForTesla
//

import SwiftUI
import RumskrotAppsKit

/// "Help shape Auth for Tesla": the About card that invites testers into the
/// public TestFlight beta (#63).
///
/// The words and the link come from RumskrotAppsKit's `BetaProgram`, as in
/// every other Dansk Rumskrot app, so Auth says what the website says. The
/// look is Auth's own: a glass card with the Tools rows' layout. Like
/// `BetaProgramRow`, it never joins cold. It pushes ``AuthBetaProgramView``,
/// which explains the beta before it offers the join.
struct AboutViewBeta: View {
    let program: BetaProgram

    /// The card for this app, or `nil` when it has no public beta.
    init?(bundleID: String = Bundle.main.bundleIdentifier ?? "") {
        guard let program = BetaProgram(bundleID: bundleID) else { return nil }
        self.program = program
    }

    var body: some View {
        NavigationLink {
            AuthBetaProgramView(program: program)
        } label: {
            AboutBetaRowLabel(program: program, showsChevron: true)
        }
        .buttonStyle(.plain)
        .padding(AppSpacing.cardInner)
        .glassEffect(.clear, in: .rect(cornerRadius: AppCornerRadius.container))
        .accessibilityIdentifier("betaProgram.row")
    }
}

/// The beta row's face: glyph, "Help shape Auth for Tesla", "Join the public
/// beta" and, when it pushes, a chevron. Shared with the Mac Settings pane.
struct AboutBetaRowLabel: View {
    let program: BetaProgram
    var showsChevron = false

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: "bubble.left.and.text.bubble.right")
                .font(.title2)
                .foregroundStyle(Color("TeslaRed"))
                .frame(width: 34)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(verbatim: program.rowTitle)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Text(verbatim: BetaProgram.rowSubtitle)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        IconBackgroundView {
            ScrollView {
                AboutViewBeta(bundleID: "dk.kimhansen.AuthAppForTesla")
                    .padding()
            }
        }
    }
}
