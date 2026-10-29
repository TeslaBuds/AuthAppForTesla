//
//  RefreshTrigger.swift
//  AuthAppForTesla
//
//  Why "refresh everything" runs. Every caller names its trigger, so the
//  compiler decides which ones may rotate a token that is not due (#59).
//

/// What asked for both APIs' tokens to be refreshed.
enum RefreshTrigger: String, CaseIterable, Codable, Sendable {
    /// The app opened. Only a token that is due is refreshed.
    case launch
    /// The person asked: the Refresh button, ⌘R, the menu-bar menu.
    case userRequest

    /// Whether Tesla is asked for new tokens even when the stored ones
    /// are still current. Each post rotates the refresh token, so only an
    /// explicit request does that.
    var forcesRefresh: Bool {
        switch self {
        case .launch: false
        case .userRequest: true
        }
    }
}
