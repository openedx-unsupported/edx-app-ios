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
    var defaultsMockRemover : OEXRemovable!
    
    override func setUp() {
        defaultsMockRemover = OEXMockUserDefaults().installAsStandardUserDefaults()
    }
    
    override func tearDown() {
        defaultsMockRemover.remove()
    }

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
    
    func testCanShowAppReview() {
        let config = OEXConfig(dictionary: [
            "APP_REVIEWS_ENABLED": true,
            "APP_REVIEW_URI" : "www.test.com"
            ])
        let interface = OEXInterface()
        interface.reachable = true
        let testEnvironment = TestRouterEnvironment(config: config, interface: interface)
        
        XCTAssertTrue(RatingViewController.canShowAppReview(testEnvironment))
    }
    
    func testCanShowAppReviewForAppReviewsDisabled() {
        let config = OEXConfig(dictionary: [
            "APP_REVIEWS_ENABLED": false,
            "APP_REVIEW_URI" : "www.test.com"
            ])
        let interface = OEXInterface()
        interface.reachable = true
        let testEnvironment = TestRouterEnvironment(config: config, interface: interface)
        
        XCTAssertFalse(RatingViewController.canShowAppReview(testEnvironment))
    }
    
    func testCanShowAppReviewForNilAppURI() {
        let config = OEXConfig(dictionary: [
            "APP_REVIEWS_ENABLED": true,
            ])
        let interface = OEXInterface()
        interface.reachable = true
        let testEnvironment = TestRouterEnvironment(config: config, interface: interface)
        
        XCTAssertFalse(RatingViewController.canShowAppReview(testEnvironment))
    }
    
    func testCanShowAppReviewForPositiveRating() {
        let config = OEXConfig(dictionary: [
            "APP_REVIEWS_ENABLED": true,
            "APP_REVIEW_URI" : "www.test.com"
            ])
        let interface = OEXInterface()
        interface.reachable = true
        interface.saveAppVersionWhenLastRated(nil)
        interface.saveAppRating(4)
        let testEnvironment = TestRouterEnvironment(config: config, interface: interface)
        
        XCTAssertFalse(RatingViewController.canShowAppReview(testEnvironment))
    }
    
    func testCanShowAppReviewForNegativeRating() {
        let config = OEXConfig(dictionary: [
            "APP_REVIEWS_ENABLED": true,
            "APP_REVIEW_URI" : "www.test.com"
            ])
        let interface = OEXInterface()
        interface.reachable = true
        interface.saveAppRating(3)
        interface.saveAppVersionWhenLastRated(nil)
        let testEnvironment = TestRouterEnvironment(config: config, interface: interface)
        
        XCTAssertFalse(RatingViewController.canShowAppReview(testEnvironment))
    }
}
