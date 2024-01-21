//
//  RefreshTokens.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 19/01/2024.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct RefreshFleetAPIToken: AppIntent {
    static var title: LocalizedStringResource = "Refresh Fleet API Token"
    static var description = IntentDescription("Refreshes Fleet API token, returns refreshed token.", categoryName: "Fleet API")

    static var parameterSummary: some ParameterSummary {
        Summary("Refresh Tokens")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<TokenResponseAppEntity> {
        let tokenV3 = await AuthController.shared.acquireTokenV3Silent(forceRefresh: true)
        let tokenV4 = await AuthController.shared.acquireTokenV4Silent(forceRefresh: true)
        if let token = tokenV3 ?? tokenV4
        {
            let tokenResponse = TokenResponseAppEntity(token: token)
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

