//
//  AuthWebView.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import SwiftUI
import WebKit

/// Errors that can occur during the OAuth web authentication flow.
enum AuthWebViewError: LocalizedError {
    case pageLoadFailed(URL)

    var errorDescription: String? {
        switch self {
        case .pageLoadFailed(let url):
            "Failed to load the authentication page: \(url.absoluteString)"
        }
    }
}

/// A SwiftUI view that presents Tesla's OAuth login page and intercepts the
/// redirect URL to extract the authorization code.
struct AuthWebView: View {
    let url: URL
    let redirectUrl: String
    let onResult: (Result<URL, Error>) -> Void

    @State private var page: WebPage
    @State private var isLoading = true
    @State private var loadFailed = false
    @Environment(\.dismiss) private var dismiss

    init(url: URL, redirectUrl: String, onResult: @escaping (Result<URL, Error>) -> Void) {
        self.url = url
        self.redirectUrl = redirectUrl
        self.onResult = onResult

        var configuration = WebPage.Configuration()
        configuration.websiteDataStore = .nonPersistent()
        let decider = OAuthNavigationDecider(redirectUrl: redirectUrl)
        _page = State(initialValue: WebPage(configuration: configuration, navigationDecider: decider))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                WebView(page)
                    .ignoresSafeArea(edges: .bottom)
                    .opacity(isLoading ? 0 : 1)

                if isLoading {
                    ProgressView("Loading Tesla login…")
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark.circle.fill") {
                        dismiss()
                    }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Sign in with Tesla")
            .navigationBarTitleDisplayMode(.inline)
        }
        .task {
            page.load(URLRequest(url: url))
        }
        .onChange(of: page.url) {
            guard let currentURL = page.url else { return }
            if currentURL.absoluteString.hasPrefix(redirectUrl) {
                onResult(.success(currentURL))
                dismiss()
            }
        }
        .onChange(of: page.isLoading) {
            if !page.isLoading {
                if page.url != nil {
                    isLoading = false
                    loadFailed = false
                } else {
                    loadFailed = true
                    isLoading = false
                }
            }
        }
        .overlay {
            if loadFailed {
                ContentUnavailableView {
                    Label("Unable to Load", systemImage: "wifi.exclamationmark")
                } description: {
                    Text("The login page could not be loaded. Check your connection and try again.")
                } actions: {
                    Button("Retry") {
                        isLoading = true
                        loadFailed = false
                        page.load(URLRequest(url: url))
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}

/// Intercepts navigation to detect the OAuth redirect URL and cancel
/// the navigation so the web view doesn't try to load it.
struct OAuthNavigationDecider: WebPage.NavigationDeciding {
    let redirectUrl: String

    func decidePolicy(
        for action: WebPage.NavigationAction,
        preferences: inout WebPage.NavigationPreferences
    ) async -> WKNavigationActionPolicy {
        if let url = action.request.url,
           url.absoluteString.hasPrefix(redirectUrl) {
            return .cancel
        }
        return .allow
    }
}
