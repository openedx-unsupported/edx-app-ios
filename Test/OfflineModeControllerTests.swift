//
//  OfflineModeControllerTests.swift
//  edX
//
//  Created by Akiva Leffert on 5/18/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import edX
import UIKit
import XCTest

class OfflineModeControllerTests: XCTestCase {
    
    // Temporarily disable while we figure out why this is failing when run from the terminal on xcode 7
    func disable_testVisibilityInitiallyReachable() {
        let reachability = MockReachability()
        let controller = OfflineModeController(reachability : reachability, styles : OEXStyles())
        XCTAssertTrue(controller.t_messageHidden)
    }
    
    func testVisibilityInitiallyUnreachable() {
        let reachability = MockReachability()
        reachability.networkStatus = (wifi : false, wwan : false)
        let controller = OfflineModeController(reachability : reachability, styles : OEXStyles())
        XCTAssertFalse(controller.t_messageHidden)
    }
    
    // Temporarily disable while we figure out why this is failing when run from the terminal on xcode 7
    func disable_testVisibilityTransition() {
        let reachability = MockReachability()
        reachability.networkStatus = (wifi : false, wwan : false)
        reachability.startNotifier()
        
        let controller = OfflineModeController(reachability : reachability, styles : OEXStyles())
        XCTAssertFalse(controller.t_messageHidden)
        
        let expectation = expectationWithDescription("reachability changed")
        
        let removable = addNotificationObserver(self, name: kReachabilityChangedNotification) { (_, _, removable) -> Void in
            expectation.fulfill()
        }
        
        reachability.networkStatus = (wifi : true, wwan : false)
        
        self.waitForExpectations()
        removable.remove()
        XCTAssertTrue(controller.t_messageHidden)
    }

}
