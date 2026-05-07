//
//  AuthWebView.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import SwiftUI
import WebKit

/// Owns a long-lived `WKWebView` for an in-flight OAuth flow.
///
/// The WKWebView lives on this class — held by `OwnersAuthInFlight` /
/// `FleetAuthInFlight` on `AuthViewModel` — instead of being created
/// inside a `UIViewRepresentable.makeUIView`. SwiftUI is free to
/// rebuild the parent view tree at any time (most painfully on
/// background → foreground when the user goes to grab a password from
/// their password manager), and a representable that creates its own
/// WKWebView gets a fresh one on every rebuild — losing any text the
/// user has typed but not submitted, and dropping back to Tesla's
/// email-entry page even mid-password.
///
/// By owning the `WKWebView` here and letting the representable just
/// adopt it, the same WKWebView (with its DOM, scroll position, and
/// typed input intact) is re-attached to whatever new SwiftUI host
/// shows up after a rebuild.
@MainActor
final class TeslaAuthSession {
    let webView: WKWebView
    private let coordinator: Coordinator

    /// Called when the WKWebView is about to navigate to a URL with
    /// the configured redirect prefix. Captures the full callback
    /// URL so the caller can extract `?code=…` from it.
    var onRedirect: ((URL) -> Void)?

    init(url: URL, redirectUrl: String) {
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .nonPersistent()
        let wv = WKWebView(frame: .zero, configuration: configuration)
        self.webView = wv
        let coord = Coordinator(redirectUrl: redirectUrl)
        self.coordinator = coord
        wv.navigationDelegate = coord
        coord.onRedirect = { [weak self] url in
            self?.onRedirect?(url)
        }
        wv.load(URLRequest(url: url))
    }

    fileprivate final class Coordinator: NSObject, WKNavigationDelegate {
        let redirectUrl: String
        var onRedirect: ((URL) -> Void)?
        var hasHandledRedirect = false

        init(redirectUrl: String) {
            self.redirectUrl = redirectUrl
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction
        ) async -> WKNavigationActionPolicy {
            let url = navigationAction.request.url
            if let url, url.absoluteString.hasPrefix(redirectUrl) {
                if !hasHandledRedirect {
                    hasHandledRedirect = true
                    await MainActor.run {
                        onRedirect?(url)
                    }
                }
                return .cancel
            }
            return .allow
        }
    }
}

/// Sheet content that hosts an externally-owned `TeslaAuthSession`.
/// The session's WKWebView is reattached on every body evaluation
/// instead of being recreated, so its DOM state survives parent
/// rebuilds.
struct AuthWebView: View {
    let session: TeslaAuthSession
    let onResult: (Result<URL, Error>) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            TeslaAuthWebViewWrapper(session: session)
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
                .onAppear {
                    session.onRedirect = { url in
                        onResult(.success(url))
                    }
                }
        }
    }
}

/// Re-attaches the externally-owned WKWebView whenever SwiftUI
/// reinstantiates this representable. `makeUIView` returns the same
/// WKWebView reference every time, so the user's in-progress sign-in
/// (typed email, password manager hop, anything mid-flow) survives.
private struct TeslaAuthWebViewWrapper: UIViewRepresentable {
    let session: TeslaAuthSession

    func makeUIView(context: Context) -> WKWebView {
        session.webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // The session owns the WKWebView. Nothing to update.
    }
}
