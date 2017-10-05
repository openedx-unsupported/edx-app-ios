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
    var crashlyticsEnable: Bool = false
    var answersEnable: Bool = false
    
    init(dictionary: Dictionary<String, Any>) {
    
        if let crashlyticsEnable = dictionary["CRASHLYTICS"] as? Bool {
            self.crashlyticsEnable = crashlyticsEnable
        }
        
        if let answerEnable = dictionary["ANSWERS"] as? Bool {
            self.answersEnable = answerEnable
        }
        self.branchConfig = BranchConfig(dictionary: dictionary["BRANCH"] as? Dictionary<String, Any>)
    }
}
