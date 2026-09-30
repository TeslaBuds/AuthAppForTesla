//
//  AboutTileColumnsTests.swift
//  Auth for Tesla Tests
//
//  The About grids flow into as many balanced columns as fit (#46).
//

import Foundation
import Testing
@testable import AuthAppForTesla

struct AboutTileColumnsTests {
    private func columns(_ items: Int, _ width: CGFloat) -> Int {
        AboutTileColumns.count(items: items, width: width, minimumTileWidth: 140, spacing: 8)
    }

    @Test func phoneWidthKeepsTwoColumns() {
        #expect(columns(6, 320) == 2)
        #expect(columns(4, 320) == 2)
    }

    @Test func wideWindowPutsEveryTileOnOneRow() {
        #expect(columns(6, 1400) == 6)
        #expect(columns(4, 1400) == 4)
    }

    @Test func rowsComeOutBalanced() {
        // Room for four or five: two rows of three, not four plus two.
        #expect(columns(6, 600) == 3)
        #expect(columns(6, 750) == 3)
        // Room for three friends: two rows of two, not three plus one.
        #expect(columns(4, 450) == 2)
    }

    @Test func unmeasuredWidthFallsBackToTwoColumns() {
        #expect(columns(6, 0) == 2)
        #expect(columns(1, 0) == 1)
    }
}
