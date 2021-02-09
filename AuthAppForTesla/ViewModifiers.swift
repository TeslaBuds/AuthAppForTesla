//
//  ViewModifiers.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 09/02/2021.
//

import Foundation
import SwiftUI

struct LightBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(UIColor(named: "backgroundColor")!))
                    .opacity(theme.opacity2)
                    .shadow(radius: theme.shadow)
            )
    }
}
