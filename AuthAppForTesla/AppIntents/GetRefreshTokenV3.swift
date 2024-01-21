//
//  GetRefreshToken.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 19/01/2024.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct GetRefreshTokenV3: AppIntent {
    static var title: LocalizedStringResource = "Get Owners API Refresh Token"
    static var description = IntentDescription("Returns the Owners API refresh token", categoryName: "Owners API")

    static var parameterSummary: some ParameterSummary {
        Summary("Get Owners API Refresh Token")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<TokenResponseAppEntity> {
        if let token = await AuthController.shared.acquireTokenV3Silent()
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
            tokenResponse.token = token.refresh_token
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
    static func responseSuccess(token: TokenResponseAppEntity) -> Self {
        "Got refresh token"
    }
    static var responseFailure: Self {
        "Could not get refresh token"
    }
}

