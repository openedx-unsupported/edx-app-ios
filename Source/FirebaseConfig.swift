//
//  FirebaseConfig.swift
//  edX
//
//  Created by Saeed Bashir on 8/28/18.
//  Copyright © 2018 edX. All rights reserved.
//

import Foundation

fileprivate enum FirebaseKeys: String, RawStringExtractable {
    case Enabled = "ENABLED"
    case AnalyticsEnabled = "ANALYTICS_ENABLED"
    case CloudMessagingEnabled = "CLOUD_MESSAGING_ENABLED"
}

class FirebaseConfig: NSObject {
    var enabled: Bool = false
    var analyticsEnabled: Bool = false
    var cloudMessagingEnabled: Bool = false

    init(dictionary: [String: AnyObject]) {
        let bundle = Bundle(for: type(of: self))
        let filePath = bundle.path(forResource: "GoogleService-Info", ofType: "plist") ?? ""
        if FileManager.default.fileExists(atPath: filePath) {
            enabled = dictionary[FirebaseKeys.Enabled] as? Bool ?? false
            let analyticsEnabled = dictionary[FirebaseKeys.AnalyticsEnabled] as? Bool ?? false
            let cloudMessagingEnabled = dictionary[FirebaseKeys.CloudMessagingEnabled] as? Bool ?? false

            self.analyticsEnabled = enabled && analyticsEnabled
            self.cloudMessagingEnabled = enabled && cloudMessagingEnabled
        }
    }
}

private let key = "FIREBASE"
extension OEXConfig {
    var firebaseConfig: FirebaseConfig {
        return FirebaseConfig(dictionary: self[key] as? [String:AnyObject] ?? [:])
    }
}
