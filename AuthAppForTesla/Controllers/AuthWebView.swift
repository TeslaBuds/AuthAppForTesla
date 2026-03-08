//
//  AuthWebView.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import SwiftUI
import WebKit

/// A SwiftUI view that presents Tesla's OAuth login page and intercepts the
/// redirect URL to extract the authorization code.
struct AuthWebView: View {
    let url: URL
    let redirectUrl: String
    let onResult: (Result<URL, Error>) -> Void

    @State private var page: WebPage
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
        WebView(page)
            .ignoresSafeArea()
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
