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
        IconBackgroundView {
            ScrollView {
                VStack(spacing: 16) {
                    SnippetHeaderCard()

                    SnippetOptionsCard(environment: $environment, language: $language)
                    SnippetEndpointCard(endpoint: $endpoint)

                    if token == nil {
                        SnippetEmptyCard(environment: environment)
                    } else {
                        SnippetCodeCard(snippet: snippet)
                    }
                }
                .padding(.vertical)
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

// MARK: - Cards

private struct SnippetHeaderCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Snippet Exporter")
                .font(.title)
                .bold()
            Text("Generate ready-to-paste cURL, HTTPie, Swift, and Python code for the currently active token.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .glassCard()
    }
}

private struct SnippetOptionsCard: View {
    @Binding var environment: LoginEnvironment
    @Binding var language: SnippetLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text("API")
                    .font(.headline)
                Picker("API", selection: $environment) {
                    Text("Owners API").tag(LoginEnvironment.owner)
                    Text("Fleet API").tag(LoginEnvironment.fleet)
                }
                .pickerStyle(.segmented)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Language")
                    .font(.headline)
                Picker("Language", selection: $language) {
                    ForEach(SnippetLanguage.allCases) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .glassCard()
    }
}

private struct SnippetEndpointCard: View {
    @Binding var endpoint: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Endpoint")
                .font(.title2)
                .bold()
            TextField("URL", text: $endpoint, axis: .vertical)
                .font(.footnote.monospaced())
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .glassEffect(.clear, in: .rect(cornerRadius: 16))
        }
        .glassCard()
    }
}

private struct SnippetCodeCard: View {
    let snippet: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Snippet")
                    .font(.title2)
                    .bold()
                Spacer()
                Button("Copy", systemImage: "doc.on.doc") {
                    UIPasteboard.general.setItems(
                        [[UTType.utf8PlainText.identifier: snippet]],
                        options: [.expirationDate: Date(timeIntervalSinceNow: 3600)]
                    )
                }
                .buttonStyle(.glass(.regular.tint(Color("TeslaRed"))))
                .foregroundStyle(.white)
                .accessibilityIdentifier("snippetCopyButton")
            }
            Text(snippet)
                .font(.footnote.monospaced())
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .glassEffect(.clear, in: .rect(cornerRadius: 16))
        }
        .glassCard()
    }
}

private struct SnippetEmptyCard: View {
    let environment: LoginEnvironment

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "key.slash")
                .font(.largeTitle)
                .foregroundStyle(Color("TeslaRed"))
            Text("No token signed in")
                .font(.title2)
                .bold()
            Text("Sign in to the \(environment == .owner ? "Owners" : "Fleet") API tab to generate a snippet.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .glassCard()
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
