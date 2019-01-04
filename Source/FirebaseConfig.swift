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
    case clientId = "CLIENT_ID"
    case googleAppId = "GOOGLE_APP_ID"
    case gcmSenderId = "GCM_SENDER_ID"
}

class FirebaseConfig: NSObject {
    var enabled: Bool = false
    var analyticsEnabled: Bool = false
    var cloudMessagingEnabled: Bool = false
    var apiKey: String = ""
    var clientId: String = ""
    var googleAppId: String = ""
    var gcmSenderId: String = ""
    
    init(dictionary: [String: AnyObject]) {
        enabled = dictionary[FirebaseKeys.enabled] as? Bool ?? false
        let analyticsEnabled = dictionary[FirebaseKeys.analyticsEnabled] as? Bool ?? false
        let cloudMessagingEnabled = dictionary[FirebaseKeys.cloudMessagingEnabled] as? Bool ?? false
        self.analyticsEnabled = enabled && analyticsEnabled
        self.cloudMessagingEnabled = enabled && cloudMessagingEnabled
        apiKey = dictionary[FirebaseKeys.apiKey] as? String ?? ""
        clientId = dictionary[FirebaseKeys.clientId] as? String ?? ""
        googleAppId = dictionary[FirebaseKeys.googleAppId] as? String ?? ""
        gcmSenderId = dictionary[FirebaseKeys.gcmSenderId] as? String ?? ""
    }
}

private let key = "FIREBASE"
extension OEXConfig {
    var firebaseConfig: FirebaseConfig {
        return FirebaseConfig(dictionary: self[key] as? [String:AnyObject] ?? [:])
    }
}
