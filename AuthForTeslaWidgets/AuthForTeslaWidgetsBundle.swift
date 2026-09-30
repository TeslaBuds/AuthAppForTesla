//
//  AuthForTeslaWidgetsBundle.swift
//  AuthForTeslaWidgets
//
//  Entry point of the widget extension. The same sources build the iOS
//  extension (AuthForTeslaWidgetsExtension) and the native Mac one
//  (AuthForTeslaWidgetsMacExtension).
//

import SwiftUI
import WidgetKit

@main
struct AuthForTeslaWidgetsBundle: WidgetBundle {
    var body: some Widget {
        TokenWidget()
    }
}
