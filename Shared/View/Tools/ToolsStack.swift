//
//  ToolsStack.swift
//  AuthAppForTesla
//
//  The Tools section's navigation, used by both shells: the iPhone/iPad
//  Tools tab and the Mac window's Tools section (#65, lane B). Adding a
//  Tools destination is one edit here, not one per platform.
//

import SwiftUI
import TeslaAuthKit

/// Tools with its own navigation stack, so a pushed Tools screen never
/// covers another section (#42).
struct ToolsStack: View {
    @Bindable var model: AuthViewModel
    @Binding var path: NavigationPath

    var body: some View {
        NavigationStack(path: $path) {
            ToolsView(model: model)
                .navigationDestination(for: ToolsDestination.self) { destination in
                    ToolsDestinationView(destination: destination, model: model)
                }
        }
    }
}

/// The screen for one Tools destination.
struct ToolsDestinationView: View {
    let destination: ToolsDestination
    @Bindable var model: AuthViewModel

    var body: some View {
        switch destination {
        case .jwtInspector:
            JWTInspectorView(model: model, initialInput: ToolsRouting.jwtInspectorInitialInput())
        case .snippetExporter:
            SnippetExporterView(model: model)
        case .testToken:
            TestTokenView(model: model)
        }
    }
}

/// Where Tools starts, which only screenshot scenarios change.
@MainActor
enum ToolsRouting {
    /// The initial Tools path: empty, unless a screenshot scenario wants
    /// to land on a specific Tools sub-screen.
    static func initialPath() -> NavigationPath {
        var path = NavigationPath()
        #if DEBUG
        switch ScreenshotScenario.current {
        case .jwtInspector: path.append(ToolsDestination.jwtInspector)
        case .snippetExporter: path.append(ToolsDestination.snippetExporter)
        case .testToken: path.append(ToolsDestination.testToken)
        default: break
        }
        #endif
        return path
    }

    /// Pre-fills the JWT inspector with the sample token only when the
    /// matching screenshot scenario is active.
    static func jwtInspectorInitialInput() -> String {
        #if DEBUG
        if ScreenshotScenario.current == .jwtInspector {
            return ScreenshotHarness.currentOwnersToken
        }
        #endif
        return ""
    }
}
