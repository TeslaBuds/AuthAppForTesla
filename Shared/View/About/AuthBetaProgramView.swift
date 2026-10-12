//
//  AuthBetaProgramView.swift
//  AuthAppForTesla
//

import SwiftUI
import RumskrotAppsKit

/// The public TestFlight beta, explained and then offered (#63).
///
/// Every word is RumskrotAppsKit's `BetaProgram`: the website's `#beta`
/// section verbatim, including the purchase disclaimer. The behaviour is
/// `BetaProgramView`'s: a join button that opens the TestFlight link, a share
/// button for the link, and a link to the beta on danskrumskrot.com. The
/// look is Auth's: the icon background and glass cards, as in Tools and
/// About (CaravanLevel's `BetaProgramSheet` does the same in its own style).
///
/// Pushed from the About screen on iPhone, iPad and in the Mac window, and
/// shown as a sheet from the Mac's Settings window.
struct AuthBetaProgramView: View {
    let program: BetaProgram

    var body: some View {
        IconBackgroundView {
            ScrollView {
                VStack(spacing: AppSpacing.cardGap) {
                    AuthBetaProgramHeader(program: program)
                    AuthBetaProgramJoinCard(program: program)
                    AuthBetaProgramParagraph(header: BetaProgram.howItWorksHeader, text: program.howItWorks)
                    AuthBetaProgramParagraph(header: BetaProgram.purchasesHeader, text: BetaProgram.purchases)
                    AuthBetaProgramParagraph(header: BetaProgram.feedbackHeader, text: BetaProgram.feedback)
                    AuthBetaProgramParagraph(header: BetaProgram.leavingHeader, text: program.leaving)
                }
                .frame(maxWidth: 640)
                .frame(maxWidth: .infinity)
                .padding(.top, AppSpacing.scrollTop)
                .padding(.bottom, AppSpacing.scrollBottom)
            }
        }
        .navigationTitle(Text(verbatim: BetaProgram.navigationTitle))
        .inlineNavigationTitle()
    }
}

/// Glyph, heading and the first paragraph.
private struct AuthBetaProgramHeader: View {
    let program: BetaProgram

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            Image(systemName: "bubble.left.and.text.bubble.right")
                .font(.largeTitle)
                .foregroundStyle(Color("TeslaRed"))
                .accessibilityHidden(true)
            Text(verbatim: BetaProgram.heading)
                .font(.title)
                .bold()
                .accessibilityAddTraits(.isHeader)
            Text(verbatim: program.intro)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }
}

/// Join, share and the website link, in one card.
private struct AuthBetaProgramJoinCard: View {
    let program: BetaProgram

    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: AppSpacing.md) {
            Button {
                openURL(program.testFlightURL)
            } label: {
                Label {
                    Text(verbatim: program.joinButtonTitle)
                } icon: {
                    Image(systemName: "arrow.up.right.square")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .controlSize(.large)
            .accessibilityHint(Text(verbatim: BetaProgram.joinButtonHint))
            .accessibilityIdentifier("betaProgram.join")

            ShareLink(
                item: program.testFlightURL,
                subject: Text(verbatim: program.shareSubject),
                message: Text(verbatim: program.shareMessage)
            ) {
                Label {
                    Text(verbatim: BetaProgram.shareButtonTitle)
                } icon: {
                    Image(systemName: "square.and.arrow.up")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .controlSize(.large)
            .accessibilityIdentifier("betaProgram.share")

            Link(destination: program.websiteURL) {
                Label {
                    Text(verbatim: BetaProgram.websiteLinkTitle)
                } icon: {
                    Image(systemName: "safari")
                }
                .font(.footnote)
            }
            .foregroundStyle(Color("TeslaRed"))
            .accessibilityHint(Text(verbatim: BetaProgram.websiteLinkHint))
        }
        .frame(maxWidth: .infinity)
        .glassCard()
    }
}

/// One headed paragraph, as a card with a TeslaRed headline like the
/// Siri & Shortcuts card.
private struct AuthBetaProgramParagraph: View {
    let header: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text(verbatim: header)
                .font(.headline)
                .foregroundStyle(Color("TeslaRed"))
                .accessibilityAddTraits(.isHeader)
            Text(verbatim: text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
        .glassCard()
    }
}

#if DEBUG
#Preview("Beta") {
    if let program = BetaProgram(bundleID: "dk.kimhansen.AuthAppForTesla") {
        NavigationStack {
            AuthBetaProgramView(program: program)
        }
    }
}
#endif
