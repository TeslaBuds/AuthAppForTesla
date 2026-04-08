//
//  SnippetExporterView.swift
//  AuthAppForTesla
//
//  Generates ready-to-paste HTTP-client snippets for the currently signed-in
//  Owners or Fleet API token. Useful for quickly trying an endpoint in a
//  developer's preferred language.
//

import SwiftUI
import UniformTypeIdentifiers

struct SnippetExporterView: View {
    @Bindable var model: AuthViewModel
    @State private var environment: LoginEnvironment = .owner
    @State private var language: SnippetLanguage = .curl
    @State private var endpoint: String = ""
    /// The default endpoint for the currently-selected environment, used to
    /// detect whether the user has customised the URL. If they have, we
    /// preserve their edit when switching API tabs; otherwise we follow.
    @State private var lastDefault: String = ""

    private var token: Token? {
        environment == .owner ? model.tokenV3 : model.tokenV4
    }

    private var snippet: String {
        guard let token else { return "" }
        return SnippetGenerator.snippet(language: language, url: endpoint, accessToken: token.access_token)
    }

    var body: some View {
        Form {
            SnippetEnvironmentSection(model: model, environment: $environment)
            SnippetLanguageSection(language: $language)
            SnippetEndpointSection(endpoint: $endpoint)

            if token == nil {
                Section {
                    ContentUnavailableView(
                        "No token signed in",
                        systemImage: "key.slash",
                        description: Text("Sign in to the \(environment == .owner ? "Owners" : "Fleet") API tab to generate a snippet.")
                    )
                }
            } else {
                SnippetCodeSection(snippet: snippet)
            }
        }
        .navigationTitle("Snippet Exporter")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: environment, initial: true) { _, newValue in
            adoptDefaultEndpoint(for: newValue)
        }
    }

    private func adoptDefaultEndpoint(for environment: LoginEnvironment) {
        let region = token?.region ?? .global
        let newDefault = SnippetGenerator.defaultEndpoint(for: environment, region: region)
        // Replace the URL if the user hasn't customised it (i.e. it still
        // matches the previous default), or if it's empty on first show.
        if endpoint.isEmpty || endpoint == lastDefault {
            endpoint = newDefault
        }
        lastDefault = newDefault
    }
}

private struct SnippetEnvironmentSection: View {
    @Bindable var model: AuthViewModel
    @Binding var environment: LoginEnvironment

    var body: some View {
        Section("API") {
            Picker("API", selection: $environment) {
                Text("Owners API").tag(LoginEnvironment.owner)
                Text("Fleet API").tag(LoginEnvironment.fleet)
            }
            .pickerStyle(.segmented)
        }
    }
}

private struct SnippetLanguageSection: View {
    @Binding var language: SnippetLanguage

    var body: some View {
        Section("Language") {
            Picker("Language", selection: $language) {
                ForEach(SnippetLanguage.allCases) { lang in
                    Text(lang.displayName).tag(lang)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

private struct SnippetEndpointSection: View {
    @Binding var endpoint: String

    var body: some View {
        Section("Endpoint") {
            TextField("URL", text: $endpoint, axis: .vertical)
                .font(.footnote.monospaced())
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }
    }
}

private struct SnippetCodeSection: View {
    let snippet: String

    var body: some View {
        Section("Snippet") {
            Text(snippet)
                .font(.footnote.monospaced())
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button("Copy", systemImage: "doc.on.doc") {
                UIPasteboard.general.setItems(
                    [[UTType.utf8PlainText.identifier: snippet]],
                    options: [.expirationDate: Date(timeIntervalSinceNow: 3600)]
                )
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("snippetCopyButton")
        }
    }
}

#Preview("With Token") {
    NavigationStack {
        SnippetExporterView(model: PreviewModelFactory.populatedModel())
    }
}

#Preview("Empty") {
    NavigationStack {
        SnippetExporterView(model: AuthViewModel())
    }
}
