//
//  RumskrotAppIconImage.swift
//  AuthAppForTesla
//

import SwiftUI
import RumskrotAppsKit
#if os(macOS)
import AppKit
#else
import UIKit
#endif

/// A Dansk Rumskrot app's icon, drawn from the artwork RumskrotAppsKit
/// bundles for its directory, or the entry's SF Symbol when there is none.
///
/// RumskrotAppsKit's own icon view is internal to the package, and so is its
/// `Bundle.module`, so the app reaches the package's resource bundle by the
/// name SwiftPM gives it inside the app bundle. This is the same approach as
/// CaravanLevel's `RumskrotAppIconImage`, extended to native macOS.
struct RumskrotAppIconImage: View {
    let app: RumskrotApp
    let side: CGFloat

    /// RumskrotAppsKit's resource bundle, copied into the app by Xcode.
    private static let resourceBundle: Bundle? = Bundle.main
        .url(forResource: "RumskrotShared_RumskrotAppsKit", withExtension: "bundle")
        .flatMap(Bundle.init(url:))

    /// The iOS home-screen squircle: the corner is about 22.4% of the side.
    private var cornerRadius: CGFloat { side * 0.224 }

    private var bundledImage: Image? {
        guard let bundle = Self.resourceBundle else { return nil }
        #if os(macOS)
        return bundle.image(forResource: app.iconAsset).map(Image.init(nsImage:))
        #else
        return UIImage(named: app.iconAsset, in: bundle, with: nil).map(Image.init(uiImage:))
        #endif
    }

    var body: some View {
        if let image = bundledImage {
            image
                .resizable()
                .frame(width: side, height: side)
                .clipShape(.rect(cornerRadius: cornerRadius, style: .continuous))
        } else {
            Image(systemName: app.fallbackSymbol)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: side, height: side)
                .background(.primary.opacity(0.12), in: .rect(cornerRadius: cornerRadius, style: .continuous))
        }
    }
}
