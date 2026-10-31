//
//  DuoRegressionTests.swift
//  Auth for Tesla Tests
//
//  iPhone Duo regressions as unit tests (#66, #69).
//

import Testing
import SwiftUI
@testable import AuthAppForTesla

@MainActor
struct DuoRegressionTests {
    /// #66: the iPhone was portrait-locked. The app must rotate and resize, so
    /// the iPhone keeps portrait and both landscapes and never asks for full screen.
    @Test func iPhoneIsNotOrientationLocked() throws {
        let orientations = try #require(
            Bundle.main.object(forInfoDictionaryKey: "UISupportedInterfaceOrientations") as? [String]
        )
        #expect(Set(orientations).isSuperset(of: [
            "UIInterfaceOrientationPortrait",
            "UIInterfaceOrientationLandscapeLeft",
            "UIInterfaceOrientationLandscapeRight"
        ]))
        let fullScreen = Bundle.main.object(forInfoDictionaryKey: "UIRequiresFullScreen") as? Bool
        #expect(fullScreen != true)
    }

    /// #69: a bar item with a title and no icon is not shown when the bar is
    /// vertical (the Duo's outer display). The sheet Cancel must have an icon
    /// the system can show alone: rendered icon-only, it is narrower than
    /// rendered title-only.
    @Test func sheetCancelHasAnIconForAVerticalBar() throws {
        let iconOnly = try width(of: SheetCancelButton {}.labelStyle(.iconOnly))
        let titleOnly = try width(of: SheetCancelButton {}.labelStyle(.titleOnly))
        #expect(iconOnly < titleOnly)
    }

    /// The measurement above discriminates: the old title-only Cancel renders
    /// the same with either label style, so it would fail that test.
    @Test func titleOnlyCancelHasNoIconToShow() throws {
        let iconOnly = try width(of: Button("Cancel", role: .cancel) {}.labelStyle(.iconOnly))
        let titleOnly = try width(of: Button("Cancel", role: .cancel) {}.labelStyle(.titleOnly))
        #expect(iconOnly == titleOnly)
    }

    private func width(of view: some View) throws -> CGFloat {
        let renderer = ImageRenderer(content: view.fixedSize())
        renderer.scale = 1
        return try #require(renderer.cgImage).width.cgFloat
    }
}

private extension Int {
    var cgFloat: CGFloat { CGFloat(self) }
}
