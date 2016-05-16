//
//  VersionUpgradeDataFactory.swift
//  edX
//
//  Created by Saeed Bashir on 5/24/16.
//  Copyright © 2016 edX. All rights reserved.
//

import UIKit
import XCTest

class VersionUpgradeDataFactory: NSObject {
    static let versionUpgradeInfo: [NSObject : AnyObject] = ["EDX-APP-LATEST-VERSION":"3.0.0"]
    
    static let versionUpgradeInfoWithDeadline: [NSObject : AnyObject] = ["EDX-APP-LATEST-VERSION":"3.0.0", "EDX-APP-VERSION-LAST-SUPPORTED-DATE": "30-June-2016"]
}
