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
        AuthController.shared().acquireTokenSilent { (token) in
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
        AuthController.shared().acquireTokenSilent { (token) in
            if let token = token
            {
                completion(GetAccessTokenIntentResponse.success(accessToken: token.access_token))
            }
            else
            {
                completion(GetAccessTokenIntentResponse.success(accessToken: ""))
            }
        }
    }
}
