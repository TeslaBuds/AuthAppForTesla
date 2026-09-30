//
//  TokenClipboard.swift
//  AuthAppForTesla
//
//  The one place a token string is put on the clipboard, shared by the
//  tap-to-copy cards and the Mac menu bar's copy commands.
//

import UIKit
import TeslaAuthKit
import UniformTypeIdentifiers

enum TokenClipboard {
    /// How long a copied token stays on the clipboard before the system
    /// clears it, limiting how long a bearer token sits there.
    static let lifetime: TimeInterval = 3600

    /// Copies `string` as plain text with an expiry, so the clipboard is
    /// cleared automatically.
    @MainActor
    static func copy(_ string: String) {
        UIPasteboard.general.setItems(
            [[UTType.utf8PlainText.identifier: string]],
            options: [.expirationDate: Date.now.addingTimeInterval(lifetime)]
        )
    }
}
