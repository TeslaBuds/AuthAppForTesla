//
//  sadf.swift
//  TokenIntents
//
//  Created by Kim Hansen on 15/02/2021.
//

import Foundation
import SwiftUI

class GetAccessTokenIntentHandler: NSObject, GetAccessTokenIntentHandling {
    
    func confirm(intent: GetAccessTokenIntent, completion: @escaping (GetAccessTokenIntentResponse) -> Void) {
        AuthController.shared().acquireTokenV3Silent { (token) in
            if token != nil
            {
                completion(GetAccessTokenIntentResponse(code: .ready, userActivity: nil))
            }
            else
            {
                completion(GetAccessTokenIntentResponse(code: .failure, userActivity: nil))
            }
        }
    }
    
    func handle(intent: GetAccessTokenIntent, completion: @escaping (GetAccessTokenIntentResponse) -> Void) {
        AuthController.shared().acquireTokenV3Silent { (token) in
            if let token = token
            {
                let response = GetAccessTokenIntentResponse(code: .success, userActivity: nil)
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
                completion(GetAccessTokenIntentResponse(code: .failure, userActivity: nil))
            }
        }
    }
}
