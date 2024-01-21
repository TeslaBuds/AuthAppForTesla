//
//  RefreshTokens.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 19/01/2024.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct RefreshTokensV3: AppIntent {
    static var title: LocalizedStringResource = "Refresh Owners API Token"
    static var description = IntentDescription("Refreshes Owners API token, returns refreshed access token.", categoryName: "Owners API")

    static var parameterSummary: some ParameterSummary {
        Summary("Refresh Tokens")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<TokenResponseAppEntity> {
        let tokenV3 = await AuthController.shared.acquireTokenV3Silent(forceRefresh: true)
        let tokenV4 = await AuthController.shared.acquireTokenV4Silent(forceRefresh: true)
        if let token = tokenV3 ?? tokenV4
        {
            let tokenResponse = TokenResponseAppEntity()
            tokenResponse.expiresAt = Calendar.current.dateComponents(
                [.calendar, .timeZone,
                 .era, .quarter,
                 .year, .month, .day,
                 .hour, .minute, .second, .nanosecond,
                 .weekday, .weekdayOrdinal,
                 .weekOfMonth, .weekOfYear, .yearForWeekOfYear],
                from: token.expires_at ?? Date.distantPast)
            tokenResponse.region = token.region?.rawValue
            tokenResponse.token = token.access_token
            return .result(value: tokenResponse)
        }
        else
        {
            return .result(value: TokenResponseAppEntity())
        }
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
fileprivate extension IntentDialog {
    static var responseSuccess: Self {
        "Refreshed tokens"
    }
    static var responseFailure: Self {
        "Could not refresh tokens"
    }
}

