//
//  RefreshFleetAPIToken.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 19/01/2024.
//

import Foundation
import AppIntents

struct RefreshFleetAPIToken: AppIntent {
    static var title: LocalizedStringResource = "Refresh Fleet API Token"
    static var description = IntentDescription(
        "Refreshes the Fleet API token for the currently active account, or for a specific account if you pick one. Returns the refreshed token.",
        categoryName: "Fleet API"
    )

    /// The account whose token to refresh. Optional — when left empty
    /// the intent operates on the active profile, which preserves the
    /// pre-multi-account behaviour for any existing Shortcut.
    @Parameter(
        title: "Account",
        description: "Which Fleet API account's token to refresh. Leave empty to refresh the active account."
    )
    var account: FleetAccountAppEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Refresh Fleet API Token for \(\.$account)")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<TokenResponseAppEntity> {
        let token: Token?
        let profileName: String?

        if let account, let uuid = UUID(uuidString: account.id) {
            token = await AuthController.shared.acquireTokenV4Silent(profileId: uuid, forceRefresh: true)
            profileName = account.name
        } else {
            token = await AuthController.shared.acquireTokenV4Silent(forceRefresh: true)
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
    static var responseSuccess: Self {
        "Refreshed Fleet API token"
    }
    static var responseFailure: Self {
        "Could not refresh Fleet API token"
    }
}
