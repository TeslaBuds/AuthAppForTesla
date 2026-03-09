//
//  Toast.swift
//  AuthAppForTesla
//

import SwiftUI

/// A transient notification message shown as a snackbar overlay.
struct Toast: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let systemImage: String
    let style: Style

    enum Style {
        case error
        case success
        case info

        var tint: Color {
            switch self {
            case .error: Color("TeslaRed")
            case .success: .green
            case .info: .secondary
            }
        }
    }

    static func error(_ message: String) -> Toast {
        Toast(message: message, systemImage: "exclamationmark.triangle.fill", style: .error)
    }

    static func success(_ message: String) -> Toast {
        Toast(message: message, systemImage: "checkmark.circle.fill", style: .success)
    }

    static func info(_ message: String) -> Toast {
        Toast(message: message, systemImage: "info.circle.fill", style: .info)
    }
}
