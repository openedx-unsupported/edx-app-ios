//
//  MicrosoftConfig.swift
//  edX
//
//  Created by Salman on 09/08/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

fileprivate enum MicrosoftKeys: String, RawStringExtractable {
    case enable = "ENABLED"
    case appID = "APP_ID"
}

class MicrosoftConfig: NSObject {
    @objc let enabled: Bool
    let appID: String?
    
    init(dictionary: [String: AnyObject]) {
        enabled = dictionary[MicrosoftKeys.enable] as? Bool ?? false
        appID = dictionary[MicrosoftKeys.appID] as? String
    }
}

private let key = "MICROSOFT"
extension OEXConfig {
    @objc var microsoftConfig : MicrosoftConfig {
        return MicrosoftConfig(dictionary: self[key] as? [String:AnyObject] ?? [:])
    }
}
