//
//  AppTab.swift
//  AuthAppForTesla
//

import SwiftUI
import TeslaAuthKit

/// Tab selection backed by an enum for type safety. The order of
/// `allCases` is the order of the tabs, and drives the ⌘1–⌘4 commands
/// in the Mac menu bar.
enum AppTab: Hashable, CaseIterable {
    case owners
    case fleet
    case tools
    case about

    /// The tab's title, shared by the tab bar and the View menu.
    var title: LocalizedStringKey {
        switch self {
        case .owners: "Owners API"
        case .fleet: "Fleet API"
        case .tools: "Tools"
        case .about: "About"
        }
    }

    var systemImage: String {
        switch self {
        case .owners: "steeringwheel"
        case .fleet: "car.2.fill"
        case .tools: "wrench.and.screwdriver"
        case .about: "info.circle"
        }
    }

    /// The key that selects this tab together with ⌘.
    var keyEquivalent: KeyEquivalent {
        switch self {
        case .owners: "1"
        case .fleet: "2"
        case .tools: "3"
        case .about: "4"
        }
    }

    /// The API whose tokens this tab shows, or `nil` for tabs that show
    /// no token.
    var loginEnvironment: LoginEnvironment? {
        switch self {
        case .owners: .owner
        case .fleet: .fleet
        case .tools, .about: nil
        }
    }
}

extension FocusedValues {
    /// The focused window's tab selection, so menu bar commands can read
    /// and change the tab of whichever window is frontmost.
    @Entry var selectedTab: Binding<AppTab>?
}
