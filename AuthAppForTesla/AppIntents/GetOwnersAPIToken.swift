//
//  GetOwnersAPIToken.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 19/01/2024.
//

import Foundation
import AppIntents

struct GetOwnersAPIToken: AppIntent {
    static var title: LocalizedStringResource = "Get Owners API Token"
    static var description = IntentDescription(
        "Returns the Owners API token for the currently active account, or for a specific account if you pick one.",
        categoryName: "Owners API"
    )

    /// The account whose token to return. Optional — when left empty
    /// the intent operates on the active profile, which preserves the
    /// pre-multi-account behaviour for any existing Shortcut that
    /// doesn't know about this parameter yet.
    @Parameter(
        title: "Account",
        description: "Which Owners API account's token to return. Leave empty to use the active account."
    )
    var account: OwnersAccountAppEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Get Owners API Token for \(\.$account)")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<TokenResponseAppEntity> {
        let token: Token?
        let profileName: String?

        if let account, let uuid = UUID(uuidString: account.id) {
            token = await AuthController.shared.acquireTokenV3Silent(profileId: uuid)
            profileName = account.name
        } else {
            token = await AuthController.shared.acquireTokenV3Silent()
            let collection = await AuthController.shared.loadProfiles(environment: .owner)
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
        "Got Owners API token"
    }
    static var responseFailure: Self {
        "Could not get Owners API token"
    }
}
