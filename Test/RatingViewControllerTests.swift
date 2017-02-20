//
//  RatingViewControllerTests.swift
//  edX
//
//  Created by Danial Zahid on 2/7/17.
//  Copyright © 2017 edX. All rights reserved.
//

import XCTest
@testable import edX

class RatingViewControllerTests: SnapshotTestCase {
    let environment = TestRouterEnvironment()
    
    func testDefaultContent() {
        let controller = RatingViewController(environment: environment)
        inScreenNavigationContext(controller) {
            assertSnapshotValidWithContent(controller.navigationController!)
        }
    }
    
    func testFilledStars() {
        let controller = RatingViewController(environment: environment)
        controller.setRating(5)
        inScreenNavigationContext(controller) {
            assertSnapshotValidWithContent(controller.navigationController!)
        }
    }
    
    func testPositiveRating() {
        let controller = RatingViewController(environment: environment)
        controller.setRating(5)
        controller.didSubmitRating(5)
        XCTAssertEqual(controller.alertController?.actions.count, 2)
    }
    
    func testNegativeRating() {
        let controller = RatingViewController(environment: environment)
        controller.setRating(2)
        controller.didSubmitRating(2)
        XCTAssertEqual(controller.alertController?.actions.count, 2)
    }
}
