//
//  JWTDecoder.swift
//  AuthAppForTesla
//
//  Lightweight utilities for inspecting JSON Web Tokens locally.
//  Signature verification is intentionally not performed — this is a
//  developer/diagnostic tool, not an authentication boundary.
//

import Foundation

/// A decoded representation of a JWT, suitable for display in the UI.
struct DecodedJWT: Equatable {
    /// Pretty-printed header JSON, or `nil` if the segment is missing/invalid.
    let header: String?
    /// Pretty-printed payload JSON, or `nil` if the segment is missing/invalid.
    let payload: String?
    /// The opaque signature segment as it appears in the original token.
    let signature: String?
    /// `exp` claim, if present and parseable as a Unix timestamp.
    let expiresAt: Date?
    /// `iat` claim, if present and parseable as a Unix timestamp.
    let issuedAt: Date?
    /// `iss` claim, if present.
    let issuer: String?
    /// `aud` claim. Tesla tokens use both string and array audiences.
    let audiences: [String]
    /// `scp` (Tesla / OIDC) or `scope` claim, split into individual scopes.
    let scopes: [String]
    /// `azp` claim, if present.
    let authorizedParty: String?
    /// `sub` claim, if present.
    let subject: String?
}

enum JWTDecoder {
    /// Decodes a JWT string into its constituent parts. Returns `nil` if the
    /// input does not contain at least the header and payload segments.
    static func decode(_ token: String) -> DecodedJWT? {
        let trimmed = token.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        let segments = trimmed.split(separator: ".", omittingEmptySubsequences: false).map(String.init)
        guard segments.count >= 2 else { return nil }

        let header = prettyPrintedJSON(forSegment: segments[0])
        let payloadJSON = prettyPrintedJSON(forSegment: segments[1])
        let payloadDict = parseSegment(segments[1])
        let signature = segments.count > 2 ? segments[2] : nil

        return DecodedJWT(
            header: header,
            payload: payloadJSON,
            signature: signature,
            expiresAt: payloadDict?.date(forKey: "exp"),
            issuedAt: payloadDict?.date(forKey: "iat"),
            issuer: payloadDict?["iss"] as? String,
            audiences: payloadDict?.audiences ?? [],
            scopes: payloadDict?.scopes ?? [],
            authorizedParty: payloadDict?["azp"] as? String,
            subject: payloadDict?["sub"] as? String
        )
    }

    private static func prettyPrintedJSON(forSegment segment: String) -> String? {
        guard let data = base64UrlDecode(segment),
              let object = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
              let string = String(data: pretty, encoding: .utf8)
        else { return nil }
        return string
    }

    private static func parseSegment(_ segment: String) -> [String: Any]? {
        guard let data = base64UrlDecode(segment),
              let object = try? JSONSerialization.jsonObject(with: data),
              let dict = object as? [String: Any]
        else { return nil }
        return dict
    }
}

private extension Dictionary where Key == String, Value == Any {
    func date(forKey key: String) -> Date? {
        if let interval = self[key] as? TimeInterval {
            return Date(timeIntervalSince1970: interval)
        }
        if let int = self[key] as? Int {
            return Date(timeIntervalSince1970: TimeInterval(int))
        }
        return nil
    }

    var audiences: [String] {
        if let array = self["aud"] as? [String] {
            return array
        }
        if let single = self["aud"] as? String {
            return [single]
        }
        return []
    }

    var scopes: [String] {
        if let array = self["scp"] as? [String] {
            return array
        }
        if let space = self["scope"] as? String {
            return space.split(separator: " ").map(String.init)
        }
        return []
    }
}
