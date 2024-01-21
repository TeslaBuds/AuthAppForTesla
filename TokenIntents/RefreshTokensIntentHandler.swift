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
        Task {
            let token = await AuthController.shared.acquireTokenV3Silent()
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
        Task {
            let tokenV4 = await AuthController.shared.acquireTokenV4Silent(forceRefresh: true)
            let tokenV3 = await AuthController.shared.acquireTokenV3Silent(forceRefresh: true)
            if let token = tokenV3 ?? tokenV4
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
