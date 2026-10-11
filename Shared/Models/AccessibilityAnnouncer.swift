//
//  AccessibilityAnnouncer.swift
//  AuthAppForTesla
//
//  #57: feedback that is only shown is never heard. Everything the app
//  confirms or reports with a toast or an animation is also spoken.
//

import SwiftUI

/// Speaks a message to VoiceOver (and other assistive technologies).
/// Tests substitute a recorder.
struct AccessibilityAnnouncer: Sendable {
    let announce: @MainActor @Sendable (String) -> Void

    init(announce: @escaping @MainActor @Sendable (String) -> Void) {
        self.announce = announce
    }

    /// Posts a real accessibility announcement.
    static let live = AccessibilityAnnouncer { message in
        AccessibilityNotification.Announcement(message).post()
    }

    /// What is spoken after a token card copies its token.
    static func copiedMessage(for type: TokenType) -> String {
        switch type {
        case .accessToken: String(localized: "Access token copied")
        case .refreshToken: String(localized: "Refresh token copied")
        }
    }
}
