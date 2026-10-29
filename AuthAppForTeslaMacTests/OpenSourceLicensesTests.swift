//
//  OpenSourceLicensesTests.swift
//  AuthAppForTeslaMacTests
//
//  #68 on the Mac: only the vendored SwiftKeychainWrapper is credited,
//  with its own licence and Jason Rendel's copyright.
//

import Testing
@testable import AuthAppForTeslaMac

@Suite("Mac Open Source Licenses (#68)")
struct OpenSourceLicensesTests {
    @Test("Only SwiftKeychainWrapper, with its real licence")
    func creditsOnlyShippedCode() {
        #expect(OpenSourceComponent.allCases.map(\.name) == ["SwiftKeychainWrapper"])
        #expect(OpenSourceComponent.swiftKeychainWrapper.licence.contains("Copyright (c) 2014 Jason Rendel"))
    }
}
