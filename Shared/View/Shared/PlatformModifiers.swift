//
//  PlatformModifiers.swift
//  AuthAppForTesla
//
//  iOS-only view modifiers, behind one name each, so the views in Shared/
//  compile for both the iOS app and the native Mac app (AuthAppForTesla#44).
//  On the Mac they do nothing: a Mac window has no inline navigation bar,
//  no inset-grouped list and no software keyboard.
//

import SwiftUI

extension View {
    /// `.navigationBarTitleDisplayMode(.inline)` on iOS.
    func inlineNavigationTitle() -> some View {
        #if os(iOS)
        navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    /// `.listStyle(.insetGrouped)` on iOS, the platform's inset list on the Mac.
    func insetGroupedListStyle() -> some View {
        #if os(iOS)
        listStyle(.insetGrouped)
        #else
        listStyle(.inset)
        #endif
    }

    /// No automatic capitalisation, for identifiers and secrets.
    func neverAutocapitalized() -> some View {
        #if os(iOS)
        textInputAutocapitalization(.never)
        #else
        self
        #endif
    }

    /// Word capitalisation, for names.
    func wordsAutocapitalized() -> some View {
        #if os(iOS)
        textInputAutocapitalization(.words)
        #else
        self
        #endif
    }

    /// A switch with its label on the leading edge and the switch on the
    /// trailing edge, as iOS lays out every toggle.
    func fullWidthToggle() -> some View {
        #if os(macOS)
        frame(maxWidth: .infinity, alignment: .leading)
        #else
        self
        #endif
    }
}
