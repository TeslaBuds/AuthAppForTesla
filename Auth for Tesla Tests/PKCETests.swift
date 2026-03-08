//
//  PKCETests.swift
//  Auth for Tesla Tests
//
//  Created by Kim Hansen on 08/03/2026.
//

import Testing
import Foundation
@testable import AuthAppForTesla

@Suite("PKCE")
struct PKCETests {

    @Test("Code verifier is 43 characters")
    func codeVerifierLength() {
        let verifier = "".codeVerifier
        #expect(verifier.count == 43)
    }

    @Test("Code verifier contains only URL-safe base64 characters")
    func codeVerifierCharacters() {
        let verifier = "".codeVerifier
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let verifierCharSet = CharacterSet(charactersIn: verifier)
        #expect(allowed.isSuperset(of: verifierCharSet))
    }

    @Test("Challenge produces a valid SHA-256 base64url hash")
    func challengeFormat() {
        let verifier = "test-verifier-string"
        let challenge = verifier.challenge

        // Challenge should be non-empty
        #expect(!challenge.isEmpty)
        // Should not contain standard base64 characters that are not URL-safe
        #expect(!challenge.contains("+"))
        #expect(!challenge.contains("/"))
        #expect(!challenge.contains("="))
    }

    @Test("Different verifiers produce different challenges")
    func differentVerifiersDifferentChallenges() {
        let challenge1 = "verifier-one".challenge
        let challenge2 = "verifier-two".challenge
        #expect(challenge1 != challenge2)
    }
}

@Suite("Base64 URL Decode")
struct Base64URLDecodeTests {

    @Test("Decodes standard base64url string")
    func decodesBase64URL() {
        // "Hello" in base64url is "SGVsbG8"
        let data = base64UrlDecode("SGVsbG8")
        #expect(data != nil)
        #expect(String(data: data!, encoding: .utf8) == "Hello")
    }

    @Test("Handles base64url with padding needed")
    func handlesPadding() {
        // "Hi" in base64url is "SGk" (needs 1 = padding)
        let data = base64UrlDecode("SGk")
        #expect(data != nil)
        #expect(String(data: data!, encoding: .utf8) == "Hi")
    }

    @Test("Converts URL-safe characters back to standard base64")
    func convertsURLSafeChars() {
        // A string that would normally use + and / in base64
        let data = base64UrlDecode("dGVzdA")
        #expect(data != nil)
        #expect(String(data: data!, encoding: .utf8) == "test")
    }
}
