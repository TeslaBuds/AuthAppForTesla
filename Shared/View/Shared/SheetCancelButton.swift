//
//  SheetCancelButton.swift
//  AuthAppForTesla
//
//  The one way out of a sheet (#69). It has a title, an icon and the
//  cancel role: the system shows a bar item without an icon only while the
//  bar is horizontal, and on the iPhone Duo's outer display a sheet's bar
//  is vertical by default. The `no_title_only_cancel` lint rule keeps a
//  bare `Button("Cancel")` from coming back.
//

import SwiftUI

/// Cancel for a sheet's toolbar. Place it in a `.cancellationAction` item.
struct SheetCancelButton: View {
    let action: () -> Void

    var body: some View {
        Button("Cancel", systemImage: "xmark", role: .cancel, action: action)
            #if os(macOS)
            // A Mac sheet's bar is never vertical; it keeps its push button.
            .labelStyle(.titleOnly)
            #endif
    }
}
