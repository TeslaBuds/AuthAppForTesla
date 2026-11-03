//
//  KeychainWrapper+Queries.swift
//  KeychainWrapper
//
//  Created by Jason Rendel on 9/23/14.
//  Copyright (c) 2014 Jason Rendel. All rights reserved.
//
//    The MIT License (MIT)
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.

import Foundation
import Security

extension KeychainWrapper {
    /// Builds an exact query for this wrapper’s service, access group and storage class.
    ///
    /// - parameter forKey: The key this query is for
    /// - parameter withAccessibility: Match this accessibility class when supplied.
    /// - returns: A dictionary with all the needed properties setup to access the keychain on iOS
    func setupKeychainQueryDictionary(
        forKey key: String, withAccessibility accessibility: KeychainItemAccessibility? = nil
    ) -> [String: Any] {
        // Setup default access as generic password (rather than a certificate, internet password, etc)
        var keychainQueryDictionary: [String: Any] = [kSecClass as String: kSecClassGenericPassword]

        // Uniquely identify this keychain accessor
        keychainQueryDictionary[kSecAttrService as String] = serviceName

        // Only set accessibiilty if its passed in, we don't want to default it here in case the user didn't want it set
        if let accessibility = accessibility {
            keychainQueryDictionary[kSecAttrAccessible as String] = accessibility.keychainAttrValue
        }

        // Set the keychain access group if defined
        if let accessGroup = self.accessGroup {
            keychainQueryDictionary[kSecAttrAccessGroup as String] = accessGroup
        }

        // Uniquely identify the account who will be accessing the keychain
        let encodedIdentifier: Data? = key.data(using: String.Encoding.utf8)

        keychainQueryDictionary[kSecAttrGeneric as String] = encodedIdentifier

        keychainQueryDictionary[kSecAttrAccount as String] = encodedIdentifier

        // Exact class: no synchronized fallback for device-bound grants.
        keychainQueryDictionary[kSecAttrSynchronizable as String] = iCloudSync ? kCFBooleanTrue : kCFBooleanFalse

        #if os(macOS)
        // The native Mac app must use the data-protection keychain: the
        // legacy file keychain ignores access groups, so `group.global`
        // would silently mean nothing. Synchronizable items already live
        // there; this states the intent explicitly (AuthAppForTesla#44).
        keychainQueryDictionary[kSecUseDataProtectionKeychain as String] = kCFBooleanTrue
        #endif

        return keychainQueryDictionary
    }

    /// Legacy synchronized storage and Fleet client configuration.
    /// Token grants use `deviceTokens` through the profile owner instead.
    public static let global = KeychainWrapper(
        serviceName: "AuthForTesla", accessGroup: "group.global", iCloudSync: true
    )

    /// Same app-family group on this device; synchronization is disabled.
    /// The profile owner also requires ThisDeviceOnly accessibility.
    public static let deviceTokens = KeychainWrapper(
        serviceName: "AuthForTesla", accessGroup: "group.global", iCloudSync: false
    )
}
