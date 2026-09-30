//
//  TokenClipboard.swift
//  AuthAppForTesla
//
//  The one place a token string is put on the clipboard, shared by the
//  tap-to-copy cards, the tools and the menu bar's copy commands.
//
//  iOS: `UIPasteboard` with an expiration date, so the system clears it.
//  macOS: `NSPasteboard` has no expiry, so a copy is marked concealed and
//  transient (clipboard managers skip it) and cleared after the same hour
//  if it is still ours and the app is still running (AuthAppForTesla#44, Q3).
//

import Foundation
import TeslaAuthKit
import UniformTypeIdentifiers
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

enum TokenClipboard {
    /// How long a copied token stays on the clipboard before it is cleared,
    /// limiting how long a bearer token sits there.
    static let lifetime: TimeInterval = 3600

    /// Copies `string` as plain text, cleared automatically after `lifetime`.
    @MainActor
    static func copy(_ string: String) {
        #if os(iOS)
        UIPasteboard.general.setItems(
            [[UTType.utf8PlainText.identifier: string]],
            options: [.expirationDate: Date.now.addingTimeInterval(lifetime)]
        )
        #elseif os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(string, forType: .string)
        // The nspasteboard.org markers: an empty value is the convention.
        pasteboard.setString("", forType: MacPasteboardMarkers.concealed)
        pasteboard.setString("", forType: MacPasteboardMarkers.transient)
        let owned = pasteboard.changeCount
        MacClipboardExpiry.shared.schedule(ownedChangeCount: owned, after: lifetime)
        #endif
    }

    /// The clipboard's plain text, for the iOS JWT inspector's Paste
    /// button. The Mac uses a `PasteButton`, which reads without the
    /// pasteboard-privacy prompt.
    @MainActor
    static var string: String? {
        #if os(iOS)
        UIPasteboard.general.string
        #else
        nil
        #endif
    }
}

/// Whether a scheduled clear may run: only while the clipboard still holds
/// what this app put there, so a later copy by the person is never erased.
enum ClipboardExpiryPolicy {
    static func shouldClear(ownedChangeCount: Int, currentChangeCount: Int) -> Bool {
        ownedChangeCount == currentChangeCount
    }
}

#if os(macOS)
/// The nspasteboard.org conventions clipboard managers honour.
enum MacPasteboardMarkers {
    static let concealed = NSPasteboard.PasteboardType("org.nspasteboard.ConcealedType")
    static let transient = NSPasteboard.PasteboardType("org.nspasteboard.TransientType")
}

/// Clears a copied token after its lifetime, if nothing replaced it.
@MainActor
final class MacClipboardExpiry {
    static let shared = MacClipboardExpiry()
    private var pending: Task<Void, Never>?

    func schedule(ownedChangeCount: Int, after lifetime: TimeInterval) {
        pending?.cancel()
        pending = Task { @MainActor in
            try? await Task.sleep(for: .seconds(lifetime))
            guard !Task.isCancelled else { return }
            let pasteboard = NSPasteboard.general
            if ClipboardExpiryPolicy.shouldClear(ownedChangeCount: ownedChangeCount, currentChangeCount: pasteboard.changeCount) {
                pasteboard.clearContents()
            }
        }
    }
}
#endif
