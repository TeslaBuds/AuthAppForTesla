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
    @State private var showProduct = false

    var body: some View {
        Button {
            if appId != nil {
                showProduct = true
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
        .sheet(isPresented: $showProduct) {
            if let appId {
                StoreProductView(appID: appId)
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

/// Wraps `SKStoreProductViewController` for presenting App Store product pages.
private struct StoreProductView: UIViewControllerRepresentable {
    let appID: String

    func makeUIViewController(context: Context) -> SKStoreProductViewController {
        let controller = SKStoreProductViewController()
        controller.loadProduct(withParameters: [SKStoreProductParameterITunesItemIdentifier: appID]) { _, _ in }
        return controller
    }

    func updateUIViewController(_ uiViewController: SKStoreProductViewController, context: Context) {
    }
}

#Preview {
    AboutViewFriend(name: "TeSlate", appId: nil, appUrl: "infinytum.co", icon: "TeSlate")
}
