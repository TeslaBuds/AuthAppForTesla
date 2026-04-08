//
//  JWTDecoderTests.swift
//  Auth for Tesla Tests
//

import Testing
import Foundation
@testable import AuthAppForTesla

@Suite("JWTDecoder")
struct JWTDecoderTests {

    /// Header `{"alg":"HS256","typ":"JWT"}`, payload
    /// `{"sub":"1234567890","name":"John Doe","iat":1700000000,"exp":1700003600,"scp":["read","write"]}`,
    /// signature is meaningless — we never validate it.
    private let sampleJWT = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNzAwMDAwMDAwLCJleHAiOjE3MDAwMDM2MDAsInNjcCI6WyJyZWFkIiwid3JpdGUiXX0.signature"

    @Test("Returns nil for empty input")
    func emptyInput() {
        #expect(JWTDecoder.decode("") == nil)
        #expect(JWTDecoder.decode("   \n  ") == nil)
    }

    @Test("Returns nil for non-JWT strings")
    func nonJWT() {
        #expect(JWTDecoder.decode("not-a-token") == nil)
    }

    @Test("Decodes a well-formed JWT")
    func decodesValidJWT() throws {
        let decoded = try #require(JWTDecoder.decode(sampleJWT))

        #expect(decoded.subject == "1234567890")
        #expect(decoded.scopes == ["read", "write"])
        #expect(decoded.expiresAt == Date(timeIntervalSince1970: 1_700_003_600))
        #expect(decoded.issuedAt == Date(timeIntervalSince1970: 1_700_000_000))
        #expect(decoded.signature == "signature")
    }

    @Test("Pretty-prints header and payload JSON")
    func prettyPrints() throws {
        let decoded = try #require(JWTDecoder.decode(sampleJWT))
        let header = try #require(decoded.header)
        let payload = try #require(decoded.payload)

        #expect(header.contains("\"alg\""))
        #expect(payload.contains("\"sub\""))
        #expect(payload.contains("\"scp\""))
    }

    @Test("Trims surrounding whitespace before decoding")
    func trimsWhitespace() {
        let padded = "\n  \(sampleJWT)  \n"
        #expect(JWTDecoder.decode(padded) != nil)
    }
}
