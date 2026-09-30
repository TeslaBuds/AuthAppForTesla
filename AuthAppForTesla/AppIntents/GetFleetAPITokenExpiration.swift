//
//  GetFleetAPITokenExpiration.swift
//  AuthAppForTesla
//

import Foundation
import AppIntents

/// Returns when the stored Fleet API access token expires, without
/// refreshing it (#2).
struct GetFleetAPITokenExpiration: AppIntent {
    static var title: LocalizedStringResource = "Get Fleet API Token Expiration"
    static var description = IntentDescription(
        "Returns when the Fleet API access token for the currently active account, or for a specific account if you pick one, expires. Does not refresh the token, so a shortcut can check it and open Auth for Tesla only when a refresh is needed.",
        categoryName: "Fleet API"
    )

    /// The account whose token to check. Optional — when left empty the
    /// intent looks at the active profile, like the other token actions.
    @Parameter(
        title: "Account",
        description: "Which Fleet API account's token to check. Leave empty to use the active account."
    )
    var account: FleetAccountAppEntity?

    static var parameterSummary: some ParameterSummary {
        Summary("Get Fleet API token expiration for \(\.$account)")
    }

    func perform() async throws -> some IntentResult & ReturnsValue<Date> & ProvidesDialog {
        let result = try TokenExpirationIntent.expiration(environment: .fleet, accountId: account?.id)
        return .result(value: result.date, dialog: result.dialog)
    }
}
