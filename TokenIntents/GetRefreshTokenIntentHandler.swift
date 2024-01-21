//
//  sadf.swift
//  TokenIntents
//
//  Created by Kim Hansen on 15/02/2021.
//

import Foundation
import SwiftUI

class GetRefreshTokenIntentHandler: NSObject, GetRefreshTokenIntentHandling {
    
    func confirm(intent: GetRefreshTokenIntent, completion: @escaping (GetRefreshTokenIntentResponse) -> Void) {
        Task {
            let token = await AuthController.shared.acquireTokenV3Silent()
            if token != nil
            {
                completion(GetRefreshTokenIntentResponse(code: .ready, userActivity: nil))
            }
            else
            {
                completion(GetRefreshTokenIntentResponse(code: .failure, userActivity: nil))
            }
        }
    }
    
    func handle(intent: GetRefreshTokenIntent, completion: @escaping (GetRefreshTokenIntentResponse) -> Void) {
        Task {
            let token = await AuthController.shared.acquireTokenV3Silent()
            if let token = token
            {
                let response = GetRefreshTokenIntentResponse(code: .success, userActivity: nil)
                let tokenResponse = TokenResponse(identifier: "tokenResponse", display: token.refresh_token)
                tokenResponse.expiresAt = Calendar.current.dateComponents(
                    [.calendar, .timeZone,
                     .era, .quarter,
                     .year, .month, .day,
                     .hour, .minute, .second, .nanosecond,
                     .weekday, .weekdayOrdinal,
                     .weekOfMonth, .weekOfYear, .yearForWeekOfYear],
                    from: token.expires_at ?? Date.distantPast)
                tokenResponse.region = token.region?.rawValue
                tokenResponse.token = token.refresh_token

                response.token = tokenResponse
                completion(response)
            }
            else
            {
                completion(GetRefreshTokenIntentResponse(code: .failure, userActivity: nil))
            }
        }
    }
}
