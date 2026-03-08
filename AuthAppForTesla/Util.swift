//
//  Util.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import Foundation
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

extension KeychainWrapper {
    public static let global = KeychainWrapper(serviceName: "AuthForTesla", accessGroup: "group.global", iCloudSync: true)
}

extension UserDefaults {
    public static let standard = UserDefaults(suiteName: "group.global")!
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

struct ExternalTokenRequestApplicationDescription: Decodable {
    let id: String
    let responseURLTemplate: String
}

struct ExternalTokenRequest {
    let appDescription: ExternalTokenRequestApplicationDescription
    let appData: String
}

func getUniversalLinkRequestApplicationDescription(for appId: String) -> ExternalTokenRequestApplicationDescription? {
    let filename = externalApplicationListFilenameComponents.joined(separator: ".")
    var inputFileURL: URL?
    
    let documentURL = URL.documentsDirectory.appending(path: filename)
    if FileManager.default.fileExists(atPath: documentURL.path) {
        inputFileURL = documentURL
    }
    
    if inputFileURL == nil {
        guard let defaultURL = Bundle.main.url(forResource: externalApplicationListFilenameComponents[0],
                                               withExtension: externalApplicationListFilenameComponents[1]) else {
            return nil
        }
        inputFileURL = defaultURL
    }
    
    if let inputFileURL,
       let jsonData = try? Data(contentsOf: inputFileURL),
       let descriptions = try? JSONDecoder().decode([ExternalTokenRequestApplicationDescription].self, from: jsonData),
       let match = descriptions.first(where: { $0.id == appId }) {
        return match
    }
    return nil
}

/// Downloads the latest external application list from GitHub.
func downloadLatestExternalApplicationList() async {
    let filename = externalApplicationListFilenameComponents.joined(separator: ".")
    guard let githubURL = URL(string: "https://raw.githubusercontent.com/TeslaBuds/AuthAppForTesla/main/AuthAppForTesla/\(filename)") else {
        return
    }
    
    do {
        let (data, response) = try await URLSession.shared.data(from: githubURL)
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            return
        }
        let documentURL = URL.documentsDirectory.appending(path: filename)
        try data.write(to: documentURL)
    } catch {
        // Download failed silently - the bundled list will be used as fallback
    }
}




/// Decodes a Base64-URL encoded string to Data.
func base64UrlDecode(_ value: String) -> Data? {
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
