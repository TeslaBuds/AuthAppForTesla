//
//  RefreshOwnersAPIToken.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 19/01/2024.
//

import Foundation
import AppIntents

struct RefreshOwnersAPIToken: AppIntent {
    static var title: LocalizedStringResource = "Refresh Owners API Token"
    static var description = IntentDescription(
        "Refreshes the Owners API token for the currently active account, or for a specific account if you pick one. Returns the refreshed token.",
        categoryName: "Owners API"
    )

    /// The account whose token to refresh. Optional — when left empty
    /// the intent operates on the active profile, which preserves the
    /// pre-multi-account behaviour for any existing Shortcut.
    @Parameter(
        title: "Account",
        description: "Which Owners API account's token to refresh. Leave empty to refresh the active account."
    )
    var account: OwnersAccountAppEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Refresh Owners API Token for \(\.$account)")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<TokenResponseAppEntity> {
        let token: Token?
        let profileName: String?

        if let account, let uuid = UUID(uuidString: account.id) {
            token = await AuthController.shared.acquireTokenV3Silent(profileId: uuid, forceRefresh: true)
            profileName = account.name
        } else {
            token = await AuthController.shared.acquireTokenV3Silent(forceRefresh: true)
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
    static var responseSuccess: Self {
        "Refreshed Owners API token"
    }
    static var responseFailure: Self {
        "Could not refresh Owners API token"
    }
}
