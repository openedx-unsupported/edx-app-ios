//
//  AppleConfig.swift
//  edX
//
//  Created by Salman on 24/08/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import UIKit

fileprivate enum AppleKeys: String, RawStringExtractable {
    case enable = "ENABLED"
}

class AppleConfig: NSObject {
    @objc let enabled: Bool
    
    init(dictionary: [String: AnyObject]) {
        enabled = dictionary[AppleKeys.enable] as? Bool ?? false
    }
}

private let key = "APPLE"
extension OEXConfig {
    @objc var appleConfig : AppleConfig {
        return AppleConfig(dictionary: self[key] as? [String:AnyObject] ?? [:])
    }
}
