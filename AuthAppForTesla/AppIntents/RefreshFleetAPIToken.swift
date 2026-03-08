//
//  RefreshTokens.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 19/01/2024.
//

import Foundation
import AppIntents

struct RefreshFleetAPIToken: AppIntent {
    static var title: LocalizedStringResource = "Refresh Fleet API Token"
    static var description = IntentDescription("Refreshes Fleet API token, returns refreshed token.", categoryName: "Fleet API")

    static var parameterSummary: some ParameterSummary {
        Summary("Refresh Fleet API Token")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<TokenResponseAppEntity> {
        let tokenV3 = await AuthController.shared.acquireTokenV3Silent(forceRefresh: true)
        let tokenV4 = await AuthController.shared.acquireTokenV4Silent(forceRefresh: true)
        if let token = tokenV3 ?? tokenV4 {
            return .result(value: TokenResponseAppEntity(token: token))
        } else {
            return .result(value: TokenResponseAppEntity())
        }
    }
}

private extension IntentDialog {
    static var responseSuccess: Self {
        "Refreshed Fleet API token"
    }
    static var responseFailure: Self {
        "Could not refresh Fleet API token"
    }
}

