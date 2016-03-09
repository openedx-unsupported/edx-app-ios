//
//  EndToEndConfig.swift
//  edX
//
//  Created by Akiva Leffert on 3/8/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

class EndToEndConfig {
    let emailTemplate: String

    init(info: [String:AnyObject]) {
        emailTemplate = (info["EMAIL_TEMPLATE"] as? String) ?? "test-{unique_id}@example.com"
    }

    convenience init() {
        let path = NSBundle(forClass: self.dynamicType).pathForResource("config", ofType: "plist")!
        let config = NSDictionary(contentsOfFile: path)!
        self.init(info:(config["END_TO_END_TEST"] as? [String:AnyObject]) ?? [:])
    }
}