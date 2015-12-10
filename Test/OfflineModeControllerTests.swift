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
    
    func testVisibilityInitiallyReachable() {
        let reachability = MockReachability()
        let controller = OfflineModeController(reachability : reachability)
        XCTAssertTrue(controller.t_messageHidden)
    }
    
    func testVisibilityInitiallyUnreachable() {
        let reachability = MockReachability()
        reachability.networkStatus = (wifi : false, wwan : false)
        let controller = OfflineModeController(reachability : reachability)
        XCTAssertFalse(controller.t_messageHidden)
    }
    
    func testVisibilityTransition() {
        let reachability = MockReachability()
        reachability.networkStatus = (wifi : false, wwan : false)
        reachability.startNotifier()
        
        let controller = OfflineModeController(reachability : reachability)
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
