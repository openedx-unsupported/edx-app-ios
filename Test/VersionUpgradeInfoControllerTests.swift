//
//  VersionUpgradeInfoControllerTests.swift
//  edX
//
//  Created by Saeed Bashir on 5/24/16.
//  Copyright © 2016 edX. All rights reserved.
//

@testable import edX
import UIKit
import XCTest

class VersionUpgradeInfoControllerTests: XCTestCase {
    func test(){
        let versionInfoController = VersionUpgradeInfoController.sharedController
        XCTAssertFalse(versionInfoController.isNewVersionAvailable)
        
        // test version upgrade available without deadline
        versionInfoController.populateHeaders(httpResponseHeaders: VersionUpgradeDataFactory.versionUpgradeInfo)
        
        XCTAssertTrue(versionInfoController.isNewVersionAvailable)
        XCTAssertNotNil(versionInfoController.latestVersion)
        XCTAssertNil(versionInfoController.lastSupportedDateString)
        
        
        // test version upgrade available with deadline
        versionInfoController.populateHeaders(httpResponseHeaders: VersionUpgradeDataFactory.versionUpgradeInfoWithDeadline)
        
        XCTAssertTrue(versionInfoController.isNewVersionAvailable)
        XCTAssertNotNil(versionInfoController.latestVersion)
        XCTAssertNotNil(versionInfoController.lastSupportedDateString)
    }
}
