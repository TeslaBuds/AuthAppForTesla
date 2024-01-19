//
//  Models.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import Foundation

enum TokenRegion: String, Codable, CaseIterable, Identifiable {
    case global, china
    
    var id: String { self.rawValue }
}

struct Token: Codable {
    let access_token: String
    let token_type: String
    let expires_in: Int
    let refresh_token: String
    var expires_at: Date?
    var region: TokenRegion?
}

struct RequestEvent : Codable, Identifiable {
    let id: Date
    let when: Date
    let message: String
}

enum LoginEnvironment {
    case owner
    case fleet
}
