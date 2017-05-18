//
//  EndToEndConfig.swift
//  edX
//
//  Created by Akiva Leffert on 3/8/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
import edXCore

class EndToEndConfig {
    let emailTemplate: String

    init(info: [String:AnyObject]) {
        emailTemplate = (info["EMAIL_TEMPLATE"] as? String) ?? "test-{unique_id}@example.com"
    }
}

extension OEXConfig {
    var endToEndConfig : EndToEndConfig {
        return EndToEndConfig(info: (self.object(forKey: "END_TO_END_TESTS") as? [String:AnyObject]) ?? [:])
    }
}
