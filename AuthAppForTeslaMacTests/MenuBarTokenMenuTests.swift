//
//  MenuBarTokenMenuTests.swift
//  AuthAppForTeslaMacTests
//

import Foundation
import Testing
import TeslaAuthKit
@testable import AuthAppForTeslaMac

@Suite("Menu-bar token menu and Mac clipboard")
struct MenuBarTokenMenuTests {
    private func profile(_ name: String, expiresIn: TimeInterval?, now: Date) -> TokenProfile {
        TokenProfile(name: name, token: Token(access_token: "a", token_type: "bearer", expires_in: 28800,
                                              refresh_token: "r", expires_at: expiresIn.map { now.addingTimeInterval($0) }, region: .global))
    }

    @Test("A profile shows how long its access token has left, and which is active")
    func labelShowsCountdown() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let label = MenuBarProfileSection.label(for: profile("Personal", expiresIn: 7080, now: now), isActive: true, now: now)
        #expect(label.hasPrefix("✓ Personal — valid for "))
        #expect(label.contains("1"))
        #expect(label.contains("58"))
    }

    @Test("An expired token says so; an inactive one has no check")
    func labelExpired() {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let label = MenuBarProfileSection.label(for: profile("Work", expiresIn: -60, now: now), isActive: false, now: now)
        #expect(label == "Work — access token expired")
    }

    @Test("A scheduled clear only runs while the clipboard is still ours")
    func clipboardExpiryPolicy() {
        #expect(ClipboardExpiryPolicy.shouldClear(ownedChangeCount: 7, currentChangeCount: 7))
        #expect(!ClipboardExpiryPolicy.shouldClear(ownedChangeCount: 7, currentChangeCount: 8))
    }
}
