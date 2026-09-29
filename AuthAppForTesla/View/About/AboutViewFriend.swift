//
//  AboutViewFriend.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI
import SafariServices

struct AboutViewFriend: View {
    let name: String
    let appId: String?
    let appUrl: String?
    let icon: String

    @Environment(\.openURL) private var openURL
    @State private var safariURL: URL?
    @State private var showSafari = false

    var body: some View {
        Button {
            open()
        } label: {
            VStack(spacing: AppSpacing.sm) {
                Image(icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 60, height: 60)
                    .clipShape(.rect(cornerRadius: AppCornerRadius.small))
                Text(name)
                    .font(.subheadline)
            }
        }
        .buttonStyle(.plain)
        .padding(AppSpacing.sm)
        .shadow(radius: AppTheme.shadowRadius)
        .sheet(isPresented: $showSafari) {
            if let safariURL {
                SafariView(url: safariURL)
                    .ignoresSafeArea()
            }
        }
    }

    /// App Store links go through `openURL`, which hands off to the App Store
    /// (Mac App Store on Mac). This replaces the old `SKStoreProductViewController`
    /// presentation, which threw on teardown (#32) and was gated off on Mac (#38).
    /// Plain web links open in an in-app Safari sheet on iOS and in the default
    /// browser on Mac, where `SFSafariViewController` is not available.
    private func open() {
        guard let destination = FriendLink(appId: appId, appUrl: appUrl) else { return }
        switch destination {
        case .appStore(let url):
            openURL(url)
        case .web(let url):
#if targetEnvironment(macCatalyst)
            openURL(url)
#else
            safariURL = url
            showSafari = true
#endif
        }
    }
}

/// Where tapping a friend tile should take the user.
enum FriendLink: Equatable {
    case appStore(URL)
    case web(URL)

    /// Prefers the App Store product page when an App Store ID is known,
    /// otherwise the web URL. Returns `nil` when neither yields a valid URL.
    init?(appId: String?, appUrl: String?) {
        if let appId, !appId.isEmpty, let url = URL(string: "https://apps.apple.com/app/id\(appId)") {
            self = .appStore(url)
        } else if let appUrl, let url = URL(string: appUrl), url.scheme != nil {
            self = .web(url)
        } else {
            return nil
        }
    }
}

#if !targetEnvironment(macCatalyst)
/// Wraps `SFSafariViewController` for presenting in-app Safari browsing.
private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
    }
}
#else
private struct SafariView: View {
    let url: URL
    var body: some View { EmptyView() }
}
#endif

#Preview {
    AboutViewFriend(name: "TeSlate", appId: "1532406445", appUrl: nil, icon: "TeSlate")
}
