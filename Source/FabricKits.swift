//
//  FabricKits.swift
//  edX
//
//  Created by Saeed Bashir on 9/27/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation

@objc class FabricKits: NSObject {
    var branchConfig: BranchConfig?
    var crashlyticsEnabled: Bool = false
    var answersEnabled: Bool = false
    
    init(dictionary: Dictionary<String, Any>) {
    
        if let crashlyticsEnabled = dictionary["CRASHLYTICS"] as? Bool {
            self.crashlyticsEnabled = crashlyticsEnabled
        }
        
        if let answersEnabled = dictionary["ANSWERS"] as? Bool {
            self.answersEnabled = answersEnabled
        }
        self.branchConfig = BranchConfig(dictionary: dictionary["BRANCH"] as? Dictionary<String, Any>)
    }
}
