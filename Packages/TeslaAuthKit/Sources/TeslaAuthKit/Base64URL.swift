//
//  Base64URL.swift
//  TeslaAuthKit
//

import Foundation

/// Decodes a Base64-URL encoded string to Data.
public func base64UrlDecode(_ value: String) -> Data? {
    var base64 = value
        .replacing("-", with: "+")
        .replacing("_", with: "/")
    
    if let data = Data(base64Encoded: base64) {
        return data
    } else {
        let paddingLength = 4 - base64.count % 4
        if paddingLength < 4 {
            base64 += String(repeating: "=", count: paddingLength)
            return Data(base64Encoded: base64)
        }
    }
    
    return nil
}
