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
    @objc var analyticsEnabled: Bool = false
    @objc var cloudMessagingEnabled: Bool = false
    @objc var apiKey: String
    @objc var clientID: String
    @objc var googleAppID: String
    @objc var gcmSenderID: String
    
    init(dictionary: [String: AnyObject]) {
        enabled = dictionary[FirebaseKeys.enabled] as? Bool ?? false
        let analyticsEnabled = dictionary[FirebaseKeys.analyticsEnabled] as? Bool ?? false
        let cloudMessagingEnabled = dictionary[FirebaseKeys.cloudMessagingEnabled] as? Bool ?? false
        self.analyticsEnabled = enabled && analyticsEnabled
        self.cloudMessagingEnabled = enabled && cloudMessagingEnabled
        apiKey = dictionary[FirebaseKeys.apiKey] as? String ?? ""
        clientID = dictionary[FirebaseKeys.clientID] as? String ?? ""
        googleAppID = dictionary[FirebaseKeys.googleAppID] as? String ?? ""
        gcmSenderID = dictionary[FirebaseKeys.gcmSenderID] as? String ?? ""
    }
}

private let key = "FIREBASE"
extension OEXConfig {
    @objc var firebaseConfig: FirebaseConfig {
        return FirebaseConfig(dictionary: self[key] as? [String:AnyObject] ?? [:])
    }
}
