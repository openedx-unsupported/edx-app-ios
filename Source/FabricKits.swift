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
    
    init(dictionary: Dictionary<String, Any>) {
        self.branchConfig = BranchConfig(dictionary: dictionary["BRANCH"] as? Dictionary<String, Any>)
    }
}
