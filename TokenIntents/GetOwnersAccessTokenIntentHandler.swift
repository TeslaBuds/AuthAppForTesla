//
//  sadf.swift
//  TokenIntents
//
//  Created by Kim Hansen on 15/02/2021.
//

import Foundation
import SwiftUI

class GetOwnersAccessTokenIntentHandler: NSObject, GetOwnersAccessTokenIntentHandling {
    
    func confirm(intent: GetOwnersAccessTokenIntent, completion: @escaping (GetOwnersAccessTokenIntentResponse) -> Void) {
        AuthController.shared().acquireTokenSilent { (token) in
            if token != nil
            {
                completion(GetOwnersAccessTokenIntentResponse(code: .ready, userActivity: nil))
            }
            else
            {
                completion(GetOwnersAccessTokenIntentResponse(code: .failure, userActivity: nil))
            }
        }
    }
    
    func handle(intent: GetOwnersAccessTokenIntent, completion: @escaping (GetOwnersAccessTokenIntentResponse) -> Void) {
        AuthController.shared().acquireTokenSilent { (token) in
            if let token = token
            {
                let response = GetOwnersAccessTokenIntentResponse(code: .success, userActivity: nil)
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
                completion(GetOwnersAccessTokenIntentResponse(code: .failure, userActivity: nil))
            }
        }
    }
}
