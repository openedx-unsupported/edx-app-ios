//
//  BranchConfig.swift
//  edX
//
//  Created by Saeed Bashir on 9/27/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation

fileprivate enum BranchKeys: String, RawStringExtractable {
    case enabled = "ENABLED"
    case key = "KEY"
}

class BranchConfig: NSObject {
    
    @objc var enabled: Bool = false
    @objc var branchKey: String?
    
    init(dictionary: Dictionary<String, Any>?) {
        if let enabled = dictionary?[BranchKeys.enabled] as? Bool {
            self.enabled = enabled
        }
        branchKey = dictionary?[BranchKeys.key] as? String
    }
}

private let key = "BRANCH"
extension OEXConfig {
    @objc var branchConfig: BranchConfig {
        return BranchConfig(dictionary: self[key] as? [String:AnyObject] ?? [:])
    }
}
