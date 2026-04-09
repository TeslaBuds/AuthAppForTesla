//
//  TokenProfileAppEntities.swift
//  AuthAppForTesla
//
//  AppEntity types that let App Intents present a list of stored
//  Owners / Fleet token profiles to the user from inside the
//  Shortcuts app, so a Shortcut can pick a specific account instead
//  of always operating on the active profile.
//
//  We split into two entity types (one per environment) so each
//  intent can constrain its picker to the relevant API — picking a
//  Fleet account inside "Get Owners API Token" would be nonsensical.
//

import Foundation
import AppIntents

// MARK: - Owners

/// A stored Owners API account profile, exposed to App Intents so the
/// user can pick a specific account when building a Shortcut. Leaving
/// the corresponding intent parameter unset preserves the legacy
/// single-token behaviour (operate on whichever profile is currently
/// marked as active).
struct OwnersAccountAppEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "Owners API Account"
    )
    static var defaultQuery = OwnersAccountQuery()

    let id: String
    let name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "Owners API")
    }
}

struct OwnersAccountQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [OwnersAccountAppEntity] {
        let collection = await AuthController.shared.loadProfiles(environment: .owner)
        return collection.profiles
            .filter { identifiers.contains($0.id.uuidString) }
            .map { OwnersAccountAppEntity(id: $0.id.uuidString, name: $0.name) }
    }

    func suggestedEntities() async throws -> [OwnersAccountAppEntity] {
        let collection = await AuthController.shared.loadProfiles(environment: .owner)
        return collection.profiles.map {
            OwnersAccountAppEntity(id: $0.id.uuidString, name: $0.name)
        }
    }
}

// MARK: - Fleet

/// A stored Fleet API account profile, exposed to App Intents so the
/// user can pick a specific account when building a Shortcut. Leaving
/// the corresponding intent parameter unset preserves the legacy
/// single-token behaviour (operate on whichever profile is currently
/// marked as active).
struct FleetAccountAppEntity: AppEntity {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(
        name: "Fleet API Account"
    )
    static var defaultQuery = FleetAccountQuery()

    let id: String
    let name: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)", subtitle: "Fleet API")
    }
}

struct FleetAccountQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [FleetAccountAppEntity] {
        let collection = await AuthController.shared.loadProfiles(environment: .fleet)
        return collection.profiles
            .filter { identifiers.contains($0.id.uuidString) }
            .map { FleetAccountAppEntity(id: $0.id.uuidString, name: $0.name) }
    }

    func suggestedEntities() async throws -> [FleetAccountAppEntity] {
        let collection = await AuthController.shared.loadProfiles(environment: .fleet)
        return collection.profiles.map {
            FleetAccountAppEntity(id: $0.id.uuidString, name: $0.name)
        }
    }
}
