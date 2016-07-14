//
//  OfflineSupportViewControllerTests.swift
//  edX
//
//  Created by Saeed Bashir on 7/15/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
@testable import edX

class OfflineSupportViewControllerTests: XCTestCase {
    
    func testOfflineVisibility() {
        let environment = TestRouterEnvironment().logInTestUser()
        let controller = OfflineSupportViewController(env: environment)
        // test initial state
        XCTAssertFalse(controller.t_isShowingSnackBar)
        
        let reachability = MockReachability()
        reachability.networkStatus = (wifi : false, wwan : false)
        reachability.startNotifier()
        
        let expectation = expectationWithDescription("reachability changed")
        
        let removable = addNotificationObserver(self, name: kReachabilityChangedNotification) { (_, _, removable) -> Void in
            controller.showOfflineSnackBar(Strings.offline, selector: nil)
            expectation.fulfill()
        }
        
        reachability.networkStatus = (wifi : false, wwan : false)
        self.waitForExpectations()
        removable.remove()
        XCTAssertTrue(controller.t_isShowingSnackBar)
    }
    
}