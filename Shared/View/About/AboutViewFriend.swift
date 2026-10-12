//
//  AboutViewFriend.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI
import TeslaAuthKit
import RumskrotAppsKit
#if os(iOS)
import SafariServices
#endif

struct AboutViewFriend: View {
    let name: String
    let appId: String?
    let appUrl: String?
    let icon: String
    var tagline: String? = nil

    @State private var safariURL: URL?
    @State private var showSafari = false

    var body: some View {
        Group {
            switch FriendLink(appId: appId, appUrl: appUrl) {
            case .appStore(let appStoreID, let url):
                // The same in-app store sheet as "More from Dansk Rumskrot":
                // modal on iPhone and iPad, a closable window on the Mac.
                RumskrotAppStoreLink(appStoreID: appStoreID, url: url) { label }
            case .web(let url):
                Button {
                    openWeb(url)
                } label: {
                    label
                }
            case nil:
                label
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(verbatim: name))
        .accessibilityHint(Text(verbatim: tagline ?? ""))
        .sheet(isPresented: $showSafari) {
            if let safariURL {
                SafariView(url: safariURL)
                    .ignoresSafeArea()
            }
        }
    }

    private var label: some View {
        AboutTileLabel(name: name, tagline: tagline) { _ in
            Image(icon)
                .resizable()
                .scaledToFit()
                .clipShape(.rect(cornerRadius: AppCornerRadius.small))
        }
    }

    @Environment(\.openURL) private var openURL

    /// Plain web links open in an in-app Safari sheet on iOS and in the
    /// default browser on Mac, where `SFSafariViewController` is not available.
    private func openWeb(_ url: URL) {
#if os(macOS)
        openURL(url)
#else
        safariURL = url
        showSafari = true
#endif
    }
}

/// Where tapping a friend tile should take the user.
enum FriendLink: Equatable {
    /// The App Store item `appStoreID`, with its web URL for platforms or
    /// moments where the in-app store sheet can't be shown.
    case appStore(appStoreID: String, url: URL)
    case web(URL)

    /// Prefers the App Store product page when an App Store ID is known,
    /// otherwise the web URL. Returns `nil` when neither yields a valid URL.
    init?(appId: String?, appUrl: String?) {
        if let appId, !appId.isEmpty, let url = URL(string: "https://apps.apple.com/app/id\(appId)") {
            self = .appStore(appStoreID: appId, url: url)
        } else if let appUrl, let url = URL(string: appUrl), url.scheme != nil {
            self = .web(url)
        } else {
            return nil
        }
    }
}

#if os(iOS)
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
