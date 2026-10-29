//
//  OpenSourceComponent.swift
//  AuthAppForTesla
//
//  The third-party code the app ships, each with its own licence text
//  (#68). Adding a component means adding a case, and the compiler then
//  asks for its name, author, link and licence.
//

import Foundation

/// Third-party code compiled into the app, credited on Open Source Licenses.
enum OpenSourceComponent: String, CaseIterable, Codable, Sendable {
    /// Vendored in TeslaAuthKit (KeychainWrapper.swift,
    /// KeychainItemAccessibility.swift).
    case swiftKeychainWrapper

    var name: String {
        switch self {
        case .swiftKeychainWrapper: "SwiftKeychainWrapper"
        }
    }

    var author: String {
        switch self {
        case .swiftKeychainWrapper: "Jason Rendel"
        }
    }

    /// The project's home page.
    var link: URL? {
        switch self {
        case .swiftKeychainWrapper: URL(string: "https://github.com/jrendel/SwiftKeychainWrapper")
        }
    }

    /// The licence exactly as the project publishes it.
    var licence: String {
        switch self {
        case .swiftKeychainWrapper: """
            The MIT License (MIT)

            Copyright (c) 2014 Jason Rendel

            Permission is hereby granted, free of charge, to any person obtaining a copy
            of this software and associated documentation files (the "Software"), to deal
            in the Software without restriction, including without limitation the rights
            to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
            copies of the Software, and to permit persons to whom the Software is
            furnished to do so, subject to the following conditions:

            The above copyright notice and this permission notice shall be included in all
            copies or substantial portions of the Software.

            THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
            IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
            FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
            AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
            LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
            OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
            SOFTWARE.
            """
        }
    }
}
