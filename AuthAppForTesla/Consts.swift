//
//  Consts.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import Foundation
import UIKit

let kTeslaClientID = "81527cff06843c8634fdc09e8ac0abefb46ac849f38fe1e431c2ef2106796384"
let kTeslaSecret = "c7257eb71a564034f9419ee651c7d0e5f7aa6bfbd18bafb5c5c033b093bb2fa3"
let kTokenV2 = "dk.kimhansen.TeslaAuth.TokenV2"
let kTokenV3 = "dk.kimhansen.TeslaAuth.TokenV3"
let kRequestEventLog = "dk.kimhansen.TeslaAuth.RequestEventLog"
let kXTeslaUserAgent = "TeslaApp/4.12.0/AuthAppForTesla"
let kUserAgent = "AuthAppForTesla"

let theme = mytheme()

struct mytheme {
//    let accentColor = UIColor(named: "accentColor")!//UIColor.lightGray
//    let accentColor2 = UIColor(named: "accentColor2")!//UIColor(red: 0.02, green: 0.87, blue: 0.44, alpha: 1.00) //UIColor.green
//    let backgroundColor = UIColor(named: "backgroundColor")!//UIColor.black
    let backgroundColor2 = UIColor(named: "backgroundColor2")!//UIColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1.00)
//    let opacity = 0.9
    let opacity2 = 0.7
    let shadow: CGFloat = 4
}

let externalApplicationListFilenameComponents = ["ExternalApplicationList", "json"]

public enum TeslaError: Error, Equatable {
    case networkError(error: NSError)
    case authenticationRequired
    case authenticationFailed
    case tokenRevoked
    case noTokenToRefresh
    case tokenRefreshFailed
    case invalidOptionsForCommand
    case failedToParseData
    case failedToReloadVehicle
}
