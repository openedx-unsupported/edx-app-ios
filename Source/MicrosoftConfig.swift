//
//  MicrosoftConfig.swift
//  edX
//
//  Created by Salman on 09/08/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

fileprivate enum MicrosoftKeys: String, RawStringExtractable {
    case MicrosoftLoginEnabled = "MICROSOFT_LOGIN_ENABLED"
    case MicrosoftAppID = "MICROSOFT_APP_ID"
}

class MicrosoftConfig: NSObject {
    @objc let enabled: Bool
    let appID: String?
    
    init(dictionary: [String: AnyObject]) {
        enabled = dictionary[MicrosoftKeys.MicrosoftLoginEnabled] as? Bool ?? true
        appID = dictionary[MicrosoftKeys.MicrosoftAppID] as? String
    }
}

private let key = "MICROSOFT"
extension OEXConfig {
    @objc var microsoftConfig : MicrosoftConfig {
        return MicrosoftConfig(dictionary: self[key] as? [String:AnyObject] ?? [:])
    }
}
