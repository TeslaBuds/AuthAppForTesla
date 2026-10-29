//
//  OpenSourceLicensesTests.swift
//  Auth for Tesla Tests
//
//  #68: Open Source Licenses credited CryptoSwift, which the app no longer
//  ships, and gave every entry the same holderless "Copyright (c) 2020"
//  MIT text — the template look App Review flags.
//

import Testing
@testable import AuthAppForTesla

@Suite("Open Source Licenses (#68)")
struct OpenSourceLicensesTests {
    @Test("Only the vendored SwiftKeychainWrapper is credited")
    func creditsOnlyShippedCode() {
        #expect(OpenSourceComponent.allCases.map(\.name) == ["SwiftKeychainWrapper"])
    }

    @Test("SwiftKeychainWrapper carries its own MIT licence, Jason Rendel's copyright")
    func keychainWrapperLicence() {
        let licence = OpenSourceComponent.swiftKeychainWrapper.licence
        #expect(licence.contains("Copyright (c) 2014 Jason Rendel"))
        #expect(licence.contains("Permission is hereby granted, free of charge"))
        #expect(licence.contains("THE SOFTWARE IS PROVIDED \"AS IS\""))
        #expect(!licence.contains("Copyright (c) 2020"))
    }
}
