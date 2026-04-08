//
//  ToolsView.swift
//  AuthAppForTesla
//
//  Hub screen that lists the developer tools shipped with the app —
//  JWT inspector, snippet exporter, and the API test panel.
//

import SwiftUI

struct ToolsView: View {
    @Bindable var model: AuthViewModel

    var body: some View {
        List {
            Section {
                NavigationLink(value: ToolsDestination.jwtInspector) {
                    Label("JWT Inspector", systemImage: "magnifyingglass.circle")
                }
                NavigationLink(value: ToolsDestination.snippetExporter) {
                    Label("Snippet Exporter", systemImage: "curlybraces")
                }
                NavigationLink(value: ToolsDestination.testToken) {
                    Label("Test Your Token", systemImage: "checkmark.shield")
                }
            } footer: {
                Text("Diagnostic and developer tools that work with your stored Owners or Fleet API tokens.")
            }
        }
        .navigationTitle("Tools")
    }
}

enum ToolsDestination: Hashable {
    case jwtInspector
    case snippetExporter
    case testToken
}

#Preview {
    NavigationStack {
        ToolsView(model: AuthViewModel())
    }
}
