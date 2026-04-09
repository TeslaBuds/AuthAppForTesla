//
//  GetFleetAPIToken.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 19/01/2024.
//

import Foundation
import AppIntents

struct GetFleetAPIToken: AppIntent {
    static var title: LocalizedStringResource = "Get Fleet API Token"
    static var description = IntentDescription(
        "Returns the Fleet API token for the currently active account, or for a specific account if you pick one.",
        categoryName: "Fleet API"
    )

    /// The account whose token to return. Optional — when left empty
    /// the intent operates on the active profile, which preserves the
    /// pre-multi-account behaviour for any existing Shortcut that
    /// doesn't know about this parameter yet.
    @Parameter(
        title: "Account",
        description: "Which Fleet API account's token to return. Leave empty to use the active account."
    )
    var account: FleetAccountAppEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Get Fleet API Token for \(\.$account)")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<TokenResponseAppEntity> {
        let token: Token?
        let profileName: String?

        if let account, let uuid = UUID(uuidString: account.id) {
            token = await AuthController.shared.acquireTokenV4Silent(profileId: uuid)
            profileName = account.name
        } else {
            token = await AuthController.shared.acquireTokenV4Silent()
            let collection = await AuthController.shared.loadProfiles(environment: .fleet)
            profileName = collection.activeProfile?.name
        }

        if let token {
            return .result(value: TokenResponseAppEntity(token: token, profileName: profileName))
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
