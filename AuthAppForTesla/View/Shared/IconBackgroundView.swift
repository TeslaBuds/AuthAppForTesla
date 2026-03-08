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

#Preview {
    IconBackgroundView {
        Text("Hello Love")
            .font(.largeTitle)
    }
}
