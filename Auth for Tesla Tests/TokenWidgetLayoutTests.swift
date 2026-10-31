//
//  TokenWidgetLayoutTests.swift
//  Auth for Tesla Tests
//
//  Kemmey/DRSFramer#71 for Auth (#61): the token widget comes in every size
//  the system offers, and every size has a layout of its own — the large
//  tiles never fall back to the small or medium one.
//

import Testing
import WidgetKit
@testable import AuthAppForTesla

struct TokenWidgetLayoutTests {
    @Test func offersEverySize() {
        let families = Set(TokenWidgetLayout.families)
        let expected: Set<WidgetFamily> = [
            .systemSmall, .systemMedium, .systemLarge, .systemExtraLarge,
            .accessoryCircular, .accessoryRectangular, .accessoryInline
        ]
        #expect(expected.isSubset(of: families))
        if #available(iOS 27.0, *) {
            #expect(families.contains(.systemExtraLargePortrait))
        }
    }

    @Test func largeSizesHaveTheirOwnLayout() {
        let compact: Set<TokenWidgetLayout> = [.single, .pair]
        for family in [WidgetFamily.systemLarge, .systemExtraLarge] {
            #expect(!compact.contains(TokenWidgetLayout(family: family)), "\(family) stretches a smaller layout")
        }
    }

    @Test func everyOfferedSizeHasADistinctPlace() {
        let layouts = TokenWidgetLayout.families.map(TokenWidgetLayout.init(family:))
        // Every layout is used by at least one offered family: none is dead code.
        #expect(Set(layouts) == Set(TokenWidgetLayout.allCases))
    }
}
