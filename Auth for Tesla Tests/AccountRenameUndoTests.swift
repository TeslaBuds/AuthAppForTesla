//
//  AccountRenameUndoTests.swift
//  Auth for Tesla Tests
//
//  #55: a rename is stored at once, and Undo / Redo put the names back.
//

import Testing
import Foundation
import TeslaAuthKit
@testable import AuthAppForTesla

@Suite("Inline account rename (#55)")
@MainActor
struct AccountRenameUndoTests {
    static func model(_ fixture: ControllerFixture) async -> AuthViewModel {
        let model = AuthViewModel(summaryPublisher: fixture.summary.publisher,
                                  announcer: AccessibilityAnnouncer { _ in },
                                  controller: fixture.controller)
        await model.loadProfiles()
        return model
    }

    static func undoManager() -> UndoManager {
        let manager = UndoManager()
        manager.groupsByEvent = false
        return manager
    }

    @Test("Rename then Undo restores the previous name; Redo renames again")
    func renameUndoRedo() async throws {
        let fixture = try ControllerFixture()
        defer { fixture.summary.tearDown() }
        let model = await Self.model(fixture)
        let undo = Self.undoManager()

        undo.beginUndoGrouping()
        await model.renameProfile(id: fixture.ownersId, to: "  Family car ", environment: .owner, undoManager: undo)
        undo.endUndoGrouping()
        #expect(model.profilesV3.activeProfile?.name == "Family car")
        #expect(await fixture.controller.loadProfiles(environment: .owner).activeProfile?.name == "Family car")
        #expect(undo.canUndo)

        undo.undo()
        await model.pendingRename?.value
        #expect(model.profilesV3.activeProfile?.name == "Personal")
        #expect(await fixture.controller.loadProfiles(environment: .owner).activeProfile?.name == "Personal")
        #expect(undo.canRedo)

        undo.redo()
        await model.pendingRename?.value
        #expect(model.profilesV3.activeProfile?.name == "Family car")
    }

    @Test("A blank or unchanged name stores nothing and registers no undo")
    func blankOrSameNameIsIgnored() async throws {
        let fixture = try ControllerFixture()
        defer { fixture.summary.tearDown() }
        let model = await Self.model(fixture)
        let undo = Self.undoManager()

        undo.beginUndoGrouping()
        await model.renameProfile(id: fixture.fleetId, to: "   ", environment: .fleet, undoManager: undo)
        await model.renameProfile(id: fixture.fleetId, to: "Work", environment: .fleet, undoManager: undo)
        undo.endUndoGrouping()
        #expect(model.profilesV4.activeProfile?.name == "Work")
        #expect(!undo.canUndo)
    }

    @Test("A refused rename is reported and leaves no undo step")
    func refusedRenameIsReported() async throws {
        let fixture = try ControllerFixture()
        defer { fixture.summary.tearDown() }
        let model = await Self.model(fixture)
        fixture.storage.failReads(with: errSecInteractionNotAllowed)
        let undo = Self.undoManager()

        undo.beginUndoGrouping()
        await model.renameProfile(id: fixture.ownersId, to: "Other", environment: .owner, undoManager: undo)
        undo.endUndoGrouping()
        #expect(model.toast?.style == .error)
        #expect(!undo.canUndo)
    }
}
