//
//  RefreshTokens.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 19/01/2024.
//

import Foundation
import AppIntents

struct RefreshOwnersAPIToken: AppIntent {
    static var title: LocalizedStringResource = "Refresh Owners API Token"
    static var description = IntentDescription("Refreshes Owners API token, returns refreshed token.", categoryName: "Owners API")

    static var parameterSummary: some ParameterSummary {
        Summary("Refresh Owners API Token")
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
        "Refreshed Owners API token"
    }
    static var responseFailure: Self {
        "Could not refresh Owners API token"
    }
}

