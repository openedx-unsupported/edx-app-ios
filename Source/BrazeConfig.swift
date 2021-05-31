//
//  BrazeConfig.swift
//  edX
//
//  Created by Saeed Bashir on 4/14/21.
//  Copyright © 2021 edX. All rights reserved.
//

import Foundation

fileprivate enum Keys: String, RawStringExtractable {
    case enabled = "ENABLED"
    case apiKey = "API_KEY"
    case endPointKey = "END_POINT_KEY"
    case pushNotificationsEnabled = "PUSH_NOTIFICATIONS_ENABLED"
}

@objc class BrazeConfig: NSObject {
    @objc var enabled: Bool = false
    @objc let apiKey: String?
    @objc let endPointKey: String?
    @objc var pushNotificationsEnabled: Bool = false

    init(dictionary: [String: AnyObject]) {
        enabled = dictionary[Keys.enabled] as? Bool ?? false
        apiKey = dictionary[Keys.apiKey] as? String
        endPointKey = dictionary[Keys.endPointKey] as? String
        pushNotificationsEnabled = enabled && dictionary[Keys.pushNotificationsEnabled] as? Bool ?? false
    }
}

private let key = "BRAZE"
extension OEXConfig {
    @objc var brazeConfig: BrazeConfig {
        return BrazeConfig(dictionary: self[key] as? [String:AnyObject] ?? [:])
    }
}
