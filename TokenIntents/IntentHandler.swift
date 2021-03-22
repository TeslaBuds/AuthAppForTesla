//
//  IntentHandler.swift
//  TokenIntents
//
//  Created by Kim Hansen on 15/02/2021.
//

import Intents

class IntentHandler: INExtension {
    
    override func handler(for intent: INIntent) -> Any {
        // This is the default implementation.  If you want different objects to handle different intents,
        // you can override this and return the handler you want for that particular intent.
        
        if intent is GetAccessTokenIntent
        {
            return GetAccessTokenIntentHandler()
        }

        if intent is GetRefreshTokenIntent
        {
            return GetRefreshTokenIntentHandler()
        }

        if intent is RefreshTokensIntent
        {
            return RefreshTokensIntentHandler()
        }

        return self
    }
    
}
