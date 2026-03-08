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
    @State private var showSafari = false

    var body: some View {
        Button {
            if let appId {
                if let url = URL(string: "https://apps.apple.com/app/id\(appId)") {
                    openURL(url)
                }
            } else if appUrl != nil {
                showSafari = true
            }
        } label: {
            VStack {
                Image(icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .clipShape(.rect(cornerRadius: 12))
                    .frame(width: 60)
                Text(name)
                    .font(.subheadline)
            }
        }
        .buttonStyle(.plain)
        .padding()
        .clipShape(.rect(cornerRadius: 8))
        .shadow(radius: AppTheme.shadowRadius)
        .sheet(isPresented: $showSafari) {
            if let appUrl, let url = URL(string: appUrl) {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
    }
}

/// Wraps `SFSafariViewController` for presenting in-app Safari browsing.
private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
    }
}

#Preview {
    AboutViewFriend(name: "TeSlate", appId: nil, appUrl: "infinytum.co", icon: "TeSlate")
}
