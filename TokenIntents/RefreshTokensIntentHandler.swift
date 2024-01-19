//
//  sadf.swift
//  TokenIntents
//
//  Created by Kim Hansen on 15/02/2021.
//

import Foundation
import SwiftUI
import Intents
import Contacts

class RefreshTokensIntentHandler: NSObject, RefreshTokensIntentHandling {
    
    func confirm(intent: RefreshTokensIntent, completion: @escaping (RefreshTokensIntentResponse) -> Void) {
        AuthController.shared.acquireTokenV3Silent { (token) in
            if token != nil
            {
                completion(RefreshTokensIntentResponse(code: .ready, userActivity: nil))
            }
            else
            {
                completion(RefreshTokensIntentResponse(code: .failure, userActivity: nil))
            }
        }
    }
    
    func handle(intent: RefreshTokensIntent, completion: @escaping (RefreshTokensIntentResponse) -> Void) {
        AuthController.shared.acquireTokenV3Silent(forceRefresh: true) { (token) in
            if let token = token
            {
                let response = RefreshTokensIntentResponse(code: .success, userActivity: nil)
                let tokenResponse = TokenResponse(identifier: "tokenResponse", display: token.access_token)
                tokenResponse.expiresAt = Calendar.current.dateComponents(
                    [.calendar, .timeZone,
                     .era, .quarter,
                     .year, .month, .day,
                     .hour, .minute, .second, .nanosecond,
                     .weekday, .weekdayOrdinal,
                     .weekOfMonth, .weekOfYear, .yearForWeekOfYear],
                    from: token.expires_at ?? Date.distantPast)
                tokenResponse.region = token.region?.rawValue
                tokenResponse.token = token.access_token

                response.token = tokenResponse
                completion(response)
            }
            else
            {
                completion(RefreshTokensIntentResponse(code: .failure, userActivity: nil))
            }
        }
    }
}
