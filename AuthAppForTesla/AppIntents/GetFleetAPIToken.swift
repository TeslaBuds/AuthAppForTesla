//
//  GetRefreshToken.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 19/01/2024.
//

import Foundation
import AppIntents

struct GetFleetAPIToken: AppIntent {
    static var title: LocalizedStringResource = "Get Fleet API Token"
    static var description = IntentDescription("Returns the Fleet API token", categoryName: "Fleet API")

    static var parameterSummary: some ParameterSummary {
        Summary("Get Fleet API Token")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<TokenResponseAppEntity> {
        if let token = await AuthController.shared.acquireTokenV4Silent() {
            return .result(value: TokenResponseAppEntity(token: token))
        } else {
            return .result(value: TokenResponseAppEntity())
        }
    }
}

private extension IntentDialog {
    static func responseSuccess(token: TokenResponseAppEntity) -> Self {
        "Got Fleet API token"
    }
    static var responseFailure: Self {
        "Could not get Fleet API token"
    }
}

