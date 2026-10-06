//
//  HomeViewRefreshProblemNotice.swift
//  AuthAppForTesla
//
//  Says why the token on screen was not refreshed (#49, #50): offline
//  (nothing to do but retry) or refused (sign in again to replace it).
//  The stored token stays visible and copyable either way.
//

import SwiftUI
import TeslaAuthKit

struct HomeViewRefreshProblemNotice: View {
    let problem: TokenRefreshProblem
    var onSignInAgain: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Label {
                Text(problem.message)
                    .font(.footnote)
            } icon: {
                Image(systemName: problem.kind == .offline ? "wifi.exclamationmark" : "person.crop.circle.badge.exclamationmark")
                    .foregroundStyle(Color("TeslaRed"))
            }
            if problem.kind == .needsSignIn, let onSignInAgain {
                Button("Sign In Again", systemImage: "person.crop.circle.badge.checkmark", action: onSignInAgain)
                    .font(.footnote.bold())
                    .accessibilityIdentifier("signInAgainButton")
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("refreshProblemNotice")
    }
}

#Preview("Refused") {
    HomeViewRefreshProblemNotice(
        problem: TokenRefreshProblem(kind: .needsSignIn, reason: "login_required", refreshToken: "r"),
        onSignInAgain: {}
    )
    .padding()
}

#Preview("Offline") {
    HomeViewRefreshProblemNotice(
        problem: TokenRefreshProblem(kind: .offline, reason: "The Internet connection appears to be offline.", refreshToken: "r")
    )
    .padding()
}
