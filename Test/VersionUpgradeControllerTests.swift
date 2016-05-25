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
    let viewController = UIViewController()
    
    func testVisibilityInitialNotUpgradeable(){
        let controller = VersionUpgradeController(viewController: viewController)
        XCTAssertTrue(controller.t_messageHidden)
    }
    
    func testVisibilityUpgradeable(){
        let versionInfoController = VersionUpgradeInfoController.sharedController
        versionInfoController.populateFromHeaders(httpResponseHeaders: VersionUpgradeDataFactory.versionUpgradeInfo)
        let controller = VersionUpgradeController(viewController: viewController)
        XCTAssertFalse(controller.t_messageHidden)
    }
    
    func testVisibilityTransition() {
        
        let versionInfoController = VersionUpgradeInfoController.sharedController
        
        let controller = VersionUpgradeController(viewController: viewController)
        XCTAssertTrue(controller.t_messageHidden)
        
        let expectation = expectationWithDescription("new version available")
        
        let removable = addNotificationObserver(self, name: AppNewVersionAvailableNotification) { (_, _, removable) -> Void in
            expectation.fulfill()
        }
        
        versionInfoController.populateFromHeaders(httpResponseHeaders: VersionUpgradeDataFactory.versionUpgradeInfo)
        
        self.waitForExpectations()
        removable.remove()
        XCTAssertFalse(controller.t_messageHidden)
    }
}