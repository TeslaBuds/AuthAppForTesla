//
//  Consts.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import SwiftUI
import TeslaAuthKit

/// Shared design constants for consistent styling across the app.
enum AppTheme {
    static let shadowRadius: Double = 4
}

let externalApplicationListFilenameComponents = ["ExternalApplicationList", "json"]

public enum TeslaError: Error, Equatable {
    case networkError(error: NSError)
    case authenticationRequired
    case authenticationFailed
    case tokenRevoked
    case noTokenToRefresh
    case tokenRefreshFailed
    case invalidOptionsForCommand
    case failedToParseData
    case failedToReloadVehicle
}
