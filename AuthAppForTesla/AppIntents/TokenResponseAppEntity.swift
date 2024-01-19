//
//  TokenResponseAppEntity.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 19/01/2024.
//

import Foundation
import AppIntents

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
struct TokenResponseAppEntity: TransientAppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Tesla Token")

    @Property(title: "Token")
    var token: String

    @Property(title: "Expires At")
    var expiresAt: DateComponents?

    @Property(title: "Region")
    var region: String?

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(token)")
    }
    
    init() {
    }
}
