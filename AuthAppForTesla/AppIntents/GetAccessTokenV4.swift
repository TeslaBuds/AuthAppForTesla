//
//  GetAccessToken.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 19/01/2024.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct GetAccessTokenV4: AppIntent {
    static var title: LocalizedStringResource = "Get Fleet API Access Token"
    static var description = IntentDescription("Returns the Fleet API access token")

    static var parameterSummary: some ParameterSummary {
        Summary("Get Fleet API Access Token")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<TokenResponseAppEntity> {
        if let token = await AuthController.shared().acquireTokenV4Silent()
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
    static func responseSuccess(token: TokenResponseAppEntity) -> Self {
        "Got access token"
    }
    static var responseFailure: Self {
        "Could not get access token"
    }
}

