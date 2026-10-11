//
//  VoiceOverFeedbackTests.swift
//  Auth for Tesla Tests
//
//  #57: every toast is spoken, and copying a token says what was copied.
//

import Testing
import Foundation
import Synchronization
import TeslaAuthKit
@testable import AuthAppForTesla

/// Records what would have been announced.
final class AnnouncementRecorder: Sendable {
    private let messages = Mutex<[String]>([])
    var spoken: [String] { messages.withLock { $0 } }
    var announcer: AccessibilityAnnouncer {
        AccessibilityAnnouncer { message in self.messages.withLock { $0.append(message) } }
    }
}

@Suite("VoiceOver feedback (#57)")
@MainActor
struct VoiceOverFeedbackTests {
    @Test("Every toast is announced")
    func toastsAreAnnounced() {
        let recorder = AnnouncementRecorder()
        let model = AuthViewModel(refresher: StubRefresher(outcomes: [:]), announcer: recorder.announcer)

        model.showToast(.error("Sign-in failed: could not exchange authorization code."))
        model.showToast(.success("Switched to Work."))

        #expect(recorder.spoken == ["Sign-in failed: could not exchange authorization code.", "Switched to Work."])
    }

    @Test("A refresh failure toast is spoken")
    func refreshFailureIsSpoken() async {
        let token = Token(access_token: "a", token_type: "bearer", expires_in: 1, refresh_token: "RT",
                          expires_at: .now.addingTimeInterval(-60), region: .global)
        let recorder = AnnouncementRecorder()
        let model = AuthViewModel(
            refresher: StubRefresher(outcomes: [.owner: .needsSignIn(token, reason: "login_required")], stored: [.owner: token]),
            summaryPublisher: TokenSummaryPublisher(defaults: nil) {},
            announcer: recorder.announcer)
        await model.loadTokens()
        await model.refreshAll().value
        #expect(recorder.spoken.count == 1)
        #expect(recorder.spoken.first?.contains("Sign in again") == true)
    }

    @Test("Copying says which token was copied")
    func copyMessages() {
        #expect(AccessibilityAnnouncer.copiedMessage(for: .accessToken) == "Access token copied")
        #expect(AccessibilityAnnouncer.copiedMessage(for: .refreshToken) == "Refresh token copied")
    }

    @Test("The Mac menu-bar copy is spoken through its toast")
    func menuBarCopyIsSpoken() {
        let recorder = AnnouncementRecorder()
        let model = AuthViewModel(refresher: StubRefresher(outcomes: [:]), announcer: recorder.announcer)
        model.copyToken(.accessToken, environment: .owner)
        #expect(recorder.spoken == ["There is no token to copy. Please sign in first."])
    }
}
