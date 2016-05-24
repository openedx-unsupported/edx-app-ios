//
//  VersionUpgradeControllerTests.swift
//  edX
//
//  Created by Saeed Bashir on 5/24/16.
//  Copyright © 2016 edX. All rights reserved.
//

@testable import edX
import UIKit
import XCTest

class VersionUpgradeControllerTests: XCTestCase {
    let rootController = UIApplication.sharedApplication().keyWindow?.rootViewController
    
    func testVisibilityInitialNotUpgradeable(){
        let controller = VersionUpgradeController(viewController: rootController)
        XCTAssertTrue(controller.t_messageHidden)
    }
    
    func testVisibilityUpgradeable(){
        let versionInfoController = VersionUpgradeInfoController.sharedController
        versionInfoController.populateHeaders(httpResponseHeaders: VersionUpgradeDataFactory.versionUpgradeInfo)
        let controller = VersionUpgradeController(viewController: rootController)
        XCTAssertFalse(controller.t_messageHidden)
    }
    
    func testVisibilityTransition() {
        
        let versionInfoController = VersionUpgradeInfoController.sharedController
        
        let controller = VersionUpgradeController(viewController: rootController)
        XCTAssertTrue(controller.t_messageHidden)
        
        let expectation = expectationWithDescription("new version available")
        
        let removable = addNotificationObserver(self, name: AppNewVersionAvailableNotification) { (_, _, removable) -> Void in
            expectation.fulfill()
        }
        
        versionInfoController.populateHeaders(httpResponseHeaders: VersionUpgradeDataFactory.versionUpgradeInfo)
        
        self.waitForExpectations()
        removable.remove()
        XCTAssertFalse(controller.t_messageHidden)
    }
}