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
    case pushNotificationsEnabled = "PUSH_NOTIFICATIONS_ENABLED"
}

@objc class BrazeConfig: NSObject {
    @objc var enabled: Bool = false
    @objc var pushNotificationsEnabled: Bool = false

    init(dictionary: [String: AnyObject]) {
        enabled = dictionary[Keys.enabled] as? Bool ?? false
        pushNotificationsEnabled = enabled && dictionary[Keys.pushNotificationsEnabled] as? Bool ?? false
    }
}

private let key = "BRAZE"
extension OEXConfig {
    @objc var brazeConfig: BrazeConfig {
        return BrazeConfig(dictionary: self[key] as? [String:AnyObject] ?? [:])
    }
}
