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
}

class MicrosoftConfig: NSObject {
    let enabled: Bool
    
    init(dictionary: [String: AnyObject]) {
        enabled = dictionary[MicrosoftKeys.MicrosoftLoginEnabled] as? Bool ?? true
    }
}

private let key = "MICROSOFT"
extension OEXConfig {
    var microsoftConfig : MicrosoftConfig {
        return MicrosoftConfig(dictionary: self[key] as? [String:AnyObject] ?? [:])
    }
}

