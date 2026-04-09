//
//  IconBackgroundView.swift
//  AuthAppForTesla
//
//  Created by Nila on 20.02.21.
//

import SwiftUI

/// A container that places a decorative key/shield pattern behind its content.
/// The pattern fills the entire background so glass effects have content to distort.
struct IconBackgroundView<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        ZStack {
            Color("IconPatternBackgroundColor")
                .ignoresSafeArea()
                .overlay {
                    Image("IconPatternSVG")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .foregroundStyle(Color("IconPatternAccentColor"))
                        .ignoresSafeArea()
                }

            content
        }
    }
}

extension View {
    /// The standard glass-card treatment used throughout the app —
    /// inner padding, a clear 24pt corner glass effect, and outer
    /// horizontal padding so cards hug the screen edges symmetrically.
    /// Matches the card styling used by `HomeView` so new screens stay
    /// visually consistent without every caller duplicating the
    /// modifier chain.
    func glassCard() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .glassEffect(.clear, in: .rect(cornerRadius: 24))
            .padding(.horizontal)
    }
}

#Preview {
    IconBackgroundView {
        Text("Hello Love")
            .font(.largeTitle)
    }
}
