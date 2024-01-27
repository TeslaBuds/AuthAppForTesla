//
//  Util.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import Foundation
import CryptoKit
import SwiftDate
import UIKit

extension CGSize {
    var least: CGFloat {
        return self.width < self.height ? self.width : self.height
    }
    var most: CGFloat {
        return self.width < self.height ? self.height : self.width
    }
}

extension String {
    var sha256:String {
           get {
            let inputData = Data(self.utf8)
            let hashed = SHA256.hash(data: inputData)
            let hashString = hashed.compactMap { String(format: "%02x", $0) }.joined()
            return hashString
           }
       }
    
    func base64EncodedString() -> String {
        let inputData = Data(self.utf8)
        return inputData.base64EncodedString()
    }
}

extension KeychainWrapper {
    public static let global = KeychainWrapper.init(serviceName: "AuthForTesla", accessGroup: "group.global", iCloudSync: true)
}

extension UserDefaults {
    public static let standard = UserDefaults.init(suiteName: "group.global")!
}

extension URL {
    subscript(key: String) -> String? {
        if let components = URLComponents(string: self.absoluteString),
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
    var inputFileURL: URL?
    if var documentURL = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
        documentURL.appendPathComponent(externalApplicationListFilenameComponents.joined(separator: "."))
        if FileManager.default.fileExists(atPath: documentURL.path) {
            inputFileURL = documentURL
        }
    }
    if inputFileURL == nil {
        guard let defaultURL = Bundle.main.url(forResource: externalApplicationListFilenameComponents[0],
                                               withExtension: externalApplicationListFilenameComponents[1]) else {
            return nil
        }
        inputFileURL = defaultURL
    }
    if let jsonData = try? Data(contentsOf: inputFileURL!),
       let externalTokenRequestApplicationDescriptions = try? JSONDecoder().decode([ExternalTokenRequestApplicationDescription].self, from: jsonData),
       let externalTokenRequestApplicationDescription = externalTokenRequestApplicationDescriptions.filter({ $0.id == appId }).first {
        
        return externalTokenRequestApplicationDescription
    }
    return nil
}

//func handleUniversalLink(_ url: URL, _ model: AuthViewModel) {
//    guard url.pathComponents.count > 1 else {
//        return
//    }
//
//    let command = url.pathComponents[1]
//    switch command {
//    case "request-refresh-token":
//        if let appId = url["app_id"],
//           let appDescription: ExternalTokenRequestApplicationDescription = getUniversalLinkRequestApplicationDescription(for: appId),
//           let appData: String = url["app_data"] {
//            
//            model.externalTokenRequest = ExternalTokenRequest(appDescription: appDescription,
//                                                              appData: appData)
//        }
//        break
//    default:
//        break
//    }
//}

func downloadLatestExternalApplicationList() {
    guard let githubURL = URL(string: "https://raw.githubusercontent.com/TeslaBuds/AuthAppForTesla/main/AuthAppForTesla/\(externalApplicationListFilenameComponents.joined(separator: "."))") else {
        return
    }
    URLSession.shared.dataTask(with: githubURL) { data, response, error in
        if error != nil || data == nil {
            return
        }
        if let httpResponse = response as? HTTPURLResponse,
           !((200...299).contains(httpResponse.statusCode)) {
            return
        }
        if var documentURL = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false) {
            documentURL.appendPathComponent(externalApplicationListFilenameComponents.joined(separator: "."))
            
            try? data!.write(to: documentURL)
        }
    }.resume()
}

#if OAUTHAVAILABLE
extension UIApplication {
    @nonobjc static var topViewController: UIViewController? {
        #if OAUTHAVAILABLE
            return UIApplication.shared.topViewController
        #else
            return nil
        #endif
    }

    var topViewController: UIViewController? {
        guard let rootController = UIApplication.shared.connectedScenes.compactMap({ ($0 as? UIWindowScene)?.keyWindow }).first?.rootViewController else {
            return nil
        }
        return UIViewController.topViewController(rootController)
    }
}

extension UIViewController {
    static func topViewController(_ viewController: UIViewController) -> UIViewController {
        guard let presentedViewController = viewController.presentedViewController else {
            return viewController
        }
        #if !topVCCastDisabled
            if let navigationController = presentedViewController as? UINavigationController {
                if let visibleViewController = navigationController.visibleViewController {
                    return topViewController(visibleViewController)
                }
            } else if let tabBarController = presentedViewController as? UITabBarController {
                if let selectedViewController = tabBarController.selectedViewController {
                    return topViewController(selectedViewController)
                }
            }
        #endif
        return topViewController(presentedViewController)
    }
}
#endif


// Function to handle Base64 URL decoding
func base64UrlDecode(_ value: String) -> Data? {
    var base64 = value
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")
    
    // Decode the base64 string
    if let data = Data(base64Encoded: base64) {
        return data
    } else {
        // Try adding padding if necessary and decode again
        let paddingLength = 4 - base64.count % 4
        if paddingLength < 4 {
            base64 += String(repeating: "=", count: paddingLength)
            return Data(base64Encoded: base64)
        }
    }
    
    return nil
}
