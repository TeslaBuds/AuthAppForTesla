//
//  AnimatableFont.swift
//  AuthAppForTesla
//

import SwiftUI

/// Animatable font size modifier using the modern @Animatable macro.
@Animatable
struct AnimatableCustomFontModifier: ViewModifier {
    var size: Double

    func body(content: Content) -> some View {
        content
            .font(.system(size: size))
    }
}

extension View {
    func animatableFont(size: Double) -> some View {
        modifier(AnimatableCustomFontModifier(size: size))
    }
}
