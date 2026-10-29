//
//  Util.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import Foundation
import TeslaAuthKit
import CryptoKit
import SwiftUI

extension CGSize {
    var least: Double {
        min(width, height)
    }
    var most: Double {
        max(width, height)
    }
}

extension String {
    var sha256: String {
        let inputData = Data(utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    func base64EncodedString() -> String {
        Data(utf8).base64EncodedString()
    }
}

extension UserDefaults {
    public static let standard = AuthSharedSuite.defaults!
}

extension URL: @retroactive Identifiable {
    public var id: String { absoluteString }
}

extension URL {
    subscript(key: String) -> String? {
        if let components = URLComponents(string: absoluteString),
           let items = components.queryItems,
           let item = items.first(where: { $0.name == key }) {
            return item.value
        }
        return nil
    }
}
