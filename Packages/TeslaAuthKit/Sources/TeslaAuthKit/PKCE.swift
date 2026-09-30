//
//  PKCE.swift
//  TeslaAuthKit
//
//  The PKCE code verifier and S256 challenge for the Owners API sign-in.
//

import Foundation
import CryptoKit

extension String {
    public var codeVerifier: String {
        let verifier = "\(Date.now.ISO8601Format())\(Date.now.ISO8601Format())\(Date.now.ISO8601Format())"
            .data(using: .utf8)!.base64EncodedString()
            .replacing("+", with: "-")
            .replacing("/", with: "_")
            .replacing("=", with: "")
            .trimmingCharacters(in: .whitespaces)
            .prefix(43)
        return String(verifier)
    }

    public var challenge: String {
        let data = Data(utf8)
        let hash = SHA256.hash(data: data)
        let base64 = Data(hash).base64EncodedString()
        return base64
            .replacing("+", with: "-")
            .replacing("/", with: "_")
            .replacing("=", with: "")
    }
}
