//
//  BranchConfig.swift
//  edX
//
//  Created by Saeed Bashir on 9/27/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation

class BranchConfig: NSObject {
    
    var enabled: Bool = false
    var branchKey: String?
    
    init(dictionary: Dictionary<String, Any>?) {
        if let enabled = dictionary?["ENABLED"] as? Bool {
            self.enabled = enabled
        }
        self.branchKey = dictionary?["BRANCH_KEY"] as? String
    }
}
