//
//  AuthWebView.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import SwiftUI
import WebKit

/// A SwiftUI view that presents Tesla's OAuth login page using a WKWebView
/// and intercepts the redirect URL to extract the authorization code.
///
/// The `onResult` closure is called when the redirect is detected.
/// The caller is responsible for dismissing the sheet (e.g. by nil-ing the
/// `sheet(item:)` binding) after processing the result.
struct AuthWebView: View {
    let url: URL
    let redirectUrl: String
    let onResult: (Result<URL, Error>) -> Void

    @State private var hasHandledRedirect = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            OAuthWebViewRepresentable(
                url: url,
                redirectUrl: redirectUrl,
                onRedirect: { callbackURL in
                    guard !hasHandledRedirect else { return }
                    hasHandledRedirect = true
                    onResult(.success(callbackURL))
                }
            )
            .ignoresSafeArea(edges: .bottom)
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
    }
}

/// A `UIViewRepresentable` wrapper around `WKWebView` that intercepts
/// OAuth redirect navigations via the navigation delegate.
private struct OAuthWebViewRepresentable: UIViewRepresentable {
    let url: URL
    let redirectUrl: String
    let onRedirect: (URL) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(redirectUrl: redirectUrl, onRedirect: onRedirect)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        print("[AuthWebView] makeUIView - loading URL: \(url.absoluteString)")
        webView.load(URLRequest(url: url))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
    }

    final class Coordinator: NSObject, WKNavigationDelegate {
        let redirectUrl: String
        let onRedirect: (URL) -> Void

        init(redirectUrl: String, onRedirect: @escaping (URL) -> Void) {
            self.redirectUrl = redirectUrl
            self.onRedirect = onRedirect
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction
        ) async -> WKNavigationActionPolicy {
            let url = navigationAction.request.url
            print("[AuthWebView] decidePolicyFor: \(url?.absoluteString ?? "nil") | type: \(navigationAction.navigationType.rawValue)")
            if let url, url.absoluteString.hasPrefix(redirectUrl) {
                print("[AuthWebView] REDIRECT DETECTED - calling onRedirect")
                onRedirect(url)
                return .cancel
            }
            return .allow
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            print("[AuthWebView] didStartProvisionalNavigation: \(webView.url?.absoluteString ?? "nil")")
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            print("[AuthWebView] didFinish: \(webView.url?.absoluteString ?? "nil")")
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("[AuthWebView] didFail: \(error.localizedDescription) | url: \(webView.url?.absoluteString ?? "nil")")
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            let nsError = error as NSError
            print("[AuthWebView] didFailProvisionalNavigation: domain=\(nsError.domain) code=\(nsError.code) | desc=\(nsError.localizedDescription) | failingURL=\(nsError.userInfo["NSErrorFailingURLStringKey"] ?? "unknown")")
        }
    }
}
