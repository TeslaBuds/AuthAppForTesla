//
//  sadf.swift
//  TokenIntents
//
//  Created by Kim Hansen on 15/02/2021.
//

import Foundation
import SwiftUI

class GetAccessTokenV3IntentHandler: NSObject, GetAccessTokenV3IntentHandling {
    
    func confirm(intent: GetAccessTokenV3Intent, completion: @escaping (GetAccessTokenV3IntentResponse) -> Void) {
        AuthController.shared().acquireTokenSilent { (token) in
            if token != nil
            {
                completion(GetAccessTokenV3IntentResponse(code: .ready, userActivity: nil))
            }
            else
            {
                completion(GetAccessTokenV3IntentResponse(code: .failure, userActivity: nil))
            }
        }
    }
    
    func handle(intent: GetAccessTokenV3Intent, completion: @escaping (GetAccessTokenV3IntentResponse) -> Void) {
        AuthController.shared().acquireTokenSilent { (token) in
            if let token = token
            {
                let response = GetAccessTokenV3IntentResponse(code: .success, userActivity: nil)
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
                completion(GetAccessTokenV3IntentResponse(code: .failure, userActivity: nil))
            }
        }
    }
}
