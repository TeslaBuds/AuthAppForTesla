//
//  GetRefreshToken.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 19/01/2024.
//

import Foundation
import AppIntents

struct GetOwnersAPIToken: AppIntent {
    static var title: LocalizedStringResource = "Get Owners API Token"
    static var description = IntentDescription("Returns the Owners API token", categoryName: "Owners API")

    static var parameterSummary: some ParameterSummary {
        Summary("Get Owners API Token")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<TokenResponseAppEntity> {
        if let token = await AuthController.shared.acquireTokenV3Silent() {
            return .result(value: TokenResponseAppEntity(token: token))
        } else {
            return .result(value: TokenResponseAppEntity())
        }
    }
}

private extension IntentDialog {
    static func responseSuccess(token: TokenResponseAppEntity) -> Self {
        "Got Owners API token"
    }
    static var responseFailure: Self {
        "Could not get Owners API token"
    }
}

