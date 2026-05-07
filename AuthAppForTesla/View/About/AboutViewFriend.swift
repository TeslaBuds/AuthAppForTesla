//
//  AboutViewFriend.swift
//  AuthAppForTesla
//
//  Created by Nila on 21.02.21.
//

import SwiftUI
import SafariServices
import StoreKit

struct AboutViewFriend: View {
    let name: String
    let appId: String?
    let appUrl: String?
    let icon: String

    @State private var showSafari = false

    var body: some View {
        Button {
            if let appId {
                presentStoreProduct(appID: appId)
            } else if appUrl != nil {
                showSafari = true
            }
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
            if let appUrl, let url = URL(string: appUrl) {
                SafariView(url: url)
                    .ignoresSafeArea()
            }
        }
    }

    /// Presents an `SKStoreProductViewController` modally from UIKit,
    /// bypassing SwiftUI's sheet presentation which is incompatible with this controller.
    private func presentStoreProduct(appID: String) {
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first,
              let rootVC = windowScene.keyWindow?.rootViewController else {
            return
        }
        // Walk to the topmost presented controller so we present on top of everything.
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        let storeVC = SKStoreProductViewController()
        storeVC.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: appID]) { _, _ in }
        topVC.present(storeVC, animated: true)
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
