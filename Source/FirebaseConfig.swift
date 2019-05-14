//
//  FirebaseConfig.swift
//  edX
//
//  Created by Saeed Bashir on 8/28/18.
//  Copyright © 2018 edX. All rights reserved.
//

import Foundation

fileprivate enum FirebaseKeys: String, RawStringExtractable {
    case enabled = "ENABLED"
    case analyticsEnabled = "ANALYTICS_ENABLED"
    case cloudMessagingEnabled = "CLOUD_MESSAGING_ENABLED"
    case apiKey = "API_KEY"
    case clientID = "CLIENT_ID"
    case googleAppID = "GOOGLE_APP_ID"
    case gcmSenderID = "GCM_SENDER_ID"
}

class FirebaseConfig: NSObject {
    @objc var enabled: Bool = false
    @objc var keysConfigured: Bool = false
    @objc var analyticsEnabled: Bool = false
    @objc var cloudMessagingEnabled: Bool = false
    
    init(dictionary: [String: AnyObject]) {
        let apiKey = dictionary[FirebaseKeys.apiKey] as? String
        let cliendID = dictionary[FirebaseKeys.clientID] as? String
        let googleAppID = dictionary[FirebaseKeys.googleAppID] as? String
        let gcmSenderID = dictionary[FirebaseKeys.gcmSenderID] as? String
        keysConfigured = apiKey != nil && cliendID != nil && googleAppID != nil && gcmSenderID != nil
        enabled =  keysConfigured && (dictionary[FirebaseKeys.enabled] as? Bool == true)
        let analyticsEnabled = dictionary[FirebaseKeys.analyticsEnabled] as? Bool ?? false
        let cloudMessagingEnabled = dictionary[FirebaseKeys.cloudMessagingEnabled] as? Bool ?? false
        self.analyticsEnabled = enabled && analyticsEnabled
        self.cloudMessagingEnabled = enabled && cloudMessagingEnabled
    }
}

private let key = "FIREBASE"
extension OEXConfig {
    @objc var firebaseConfig: FirebaseConfig {
        return FirebaseConfig(dictionary: self[key] as? [String:AnyObject] ?? [:])
    }
}
