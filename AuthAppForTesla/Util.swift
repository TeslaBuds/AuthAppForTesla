//
//  Util.swift
//  AuthAppForTesla
//
//  Created by Kim Hansen on 03/02/2021.
//

import Foundation
import CryptoKit
import SwiftDate

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
    public static let global = KeychainWrapper.init(serviceName: "AuthForTesla", accessGroup: "group.infinytum.tesla", iCloudSync: true)
}

extension UserDefaults {
    public static let standard = UserDefaults.init(suiteName: "group.infinytum.tesla")!
}

func logRequestEvent(message: String) {
    var eventLog = [RequestEvent]()
    if let requestEventLogJson = UserDefaults.standard.data(forKey: kRequestEventLog), let requestEventLog = try? JSONDecoder().decode([RequestEvent].self, from: requestEventLogJson)
    {
        eventLog = requestEventLog
    }
    
    eventLog.removeAll { (event) -> Bool in
        event.when < Date.init().addingTimeInterval(TimeInterval(-60*60*12)) //25 hours
    }
    
    let event = RequestEvent(id: Date.init(), when: Date.init(), message: message)
    eventLog.append(event)
    
    if let requestEventLogJson = try? JSONEncoder().encode(eventLog) {
        UserDefaults.standard.set(requestEventLogJson, forKey: kRequestEventLog)
    }
}

func getRequestEventLog() -> [RequestEvent] {
    var eventLog = [RequestEvent]()
    if let requestEventLogJson = UserDefaults.standard.data(forKey: kRequestEventLog), let requestEventLog = try? JSONDecoder().decode([RequestEvent].self, from: requestEventLogJson)
    {
        eventLog = requestEventLog
    }
    
    return eventLog
}

func getRequestEventText() -> String {
    var eventLog = ""
    if let backgroundEventLogJson = UserDefaults.standard.data(forKey: kRequestEventLog), let backgroundEventLog = try? JSONDecoder().decode([RequestEvent].self, from: backgroundEventLogJson)
    {
        for event in backgroundEventLog {
            eventLog += "\(DateInRegion(event.when, region: Region.local).toString(DateToStringStyles.time(DateFormatter.Style.short))): \(event.message)\n"
        }
    }
    
    return eventLog
}
