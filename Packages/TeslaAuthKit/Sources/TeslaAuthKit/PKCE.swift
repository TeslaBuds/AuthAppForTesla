//
//  PKCE.swift
//  TeslaAuthKit
//
//  The PKCE code verifier and S256 challenge (RFC 7636), and the OAuth
//  `state` value, for both the Owners and the Fleet API sign-in.
//

import Foundation
import CryptoKit

/// Random values for one OAuth authorization flow (AuthAppForTesla#51).
public enum PKCE {
    /// Bytes of entropy behind a verifier: 32 bytes is 43 base64url
    /// characters, the RFC 7636 minimum length, with 256 bits of entropy.
    public static let verifierByteCount = 32

    /// A cryptographically random code verifier: 32 random bytes,
    /// base64url without padding, 43 characters.
    public static func makeCodeVerifier() -> String {
        randomBase64URL(byteCount: verifierByteCount)
    }

    /// A cryptographically random `state` value for the authorize
    /// request, checked against the redirect before any code exchange.
    public static func makeState() -> String {
        randomBase64URL(byteCount: 24)
    }

    /// `byteCount` bytes from the system CSPRNG, base64url-encoded.
    static func randomBase64URL(byteCount: Int) -> String {
        var generator = SystemRandomNumberGenerator()
        let bytes = (0..<byteCount).map { _ in UInt8.random(in: .min ... .max, using: &generator) }
        return base64URLEncode(Data(bytes))
    }

    /// Base64url without padding (RFC 4648 §5).
    public static func base64URLEncode(_ data: Data) -> String {
        data.base64EncodedString()
            .replacing("+", with: "-")
            .replacing("/", with: "_")
            .replacing("=", with: "")
    }
}

extension String {
    /// A fresh random code verifier. Kept for source compatibility; the
    /// receiver is ignored. Prefer `PKCE.makeCodeVerifier()`.
    public var codeVerifier: String {
        PKCE.makeCodeVerifier()
    }

    /// The S256 code challenge for this verifier.
    public var challenge: String {
        PKCE.base64URLEncode(Data(SHA256.hash(data: Data(utf8))))
    }
}
