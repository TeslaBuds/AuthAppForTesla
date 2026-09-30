//
//  MacMenuConfigurator.swift
//  AuthAppForTesla
//

#if targetEnvironment(macCatalyst)
import UIKit
import TeslaAuthKit

/// Catalyst adds Duplicate, Move, Rename… and Export As… to the File menu
/// of every app. This one has no documents, and SwiftUI's
/// `CommandGroupPlacement` has no group for them, so the menu builder
/// drops that group here (#37). Everything else in the menu bar comes
/// from `AppCommands`.
final class MacMenuConfigurator: UIResponder, UIApplicationDelegate {
    override func buildMenu(with builder: any UIMenuBuilder) {
        super.buildMenu(with: builder)
        guard builder.system == .main else { return }
        builder.remove(menu: .document)
    }
}
#endif
