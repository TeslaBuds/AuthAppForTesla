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
        AuthController.shared().acquireTokenV3Silent { (token) in
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
        AuthController.shared().acquireTokenV3Silent { (token) in
            if let token = token
            {
                completion(GetRefreshTokenIntentResponse.success(refreshToken: token.refresh_token))
            }
            else
            {
                completion(GetRefreshTokenIntentResponse.success(refreshToken: ""))
            }
        }
    }
}
