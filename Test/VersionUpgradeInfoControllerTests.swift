//
//  VersionUpgradeInfoControllerTests.swift
//  edX
//
//  Created by Saeed Bashir on 6/7/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

@testable import edX
import UIKit
import XCTest

class VersionUpgradeInfoControllerTests: XCTestCase {
    func testParsing(){
        let versionInfoController = VersionUpgradeInfoController.sharedController
        XCTAssertNil(versionInfoController.latestVersion)
        
        // test version upgrade available without deadline
        versionInfoController.populateFromHeaders(httpResponseHeaders: VersionUpgradeDataFactory.versionUpgradeInfo as? [String : Any])
        XCTAssertNotNil(versionInfoController.latestVersion)
        XCTAssertNil(versionInfoController.lastSupportedDateString)
        
        // test version upgrade available with deadline
        versionInfoController.populateFromHeaders(httpResponseHeaders: VersionUpgradeDataFactory.versionUpgradeInfoWithDeadline as? [String : Any])
        XCTAssertNotNil(versionInfoController.latestVersion)
        XCTAssertNotNil(versionInfoController.lastSupportedDateString)
    }
}
