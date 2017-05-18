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
        controller.setRating(rating: 5)
        inScreenNavigationContext(controller) {
            assertSnapshotValidWithContent(controller.navigationController!)
        }
    }
    
    func testPositiveRating() {
        let controller = RatingViewController(environment: environment)
        controller.setRating(rating: RatingViewController.minimumPositiveRating)
        controller.didSubmitRating(rating: RatingViewController.minimumPositiveRating)
        XCTAssertEqual(controller.alertController?.actions.count, 2)
    }
    
    func testNegativeRating() {
        let controller = RatingViewController(environment: environment)
        controller.setRating(rating: RatingViewController.minimumPositiveRating-1)
        controller.didSubmitRating(rating: RatingViewController.minimumPositiveRating-1)
        XCTAssertEqual(controller.alertController?.actions.count, 2)
    }
    
    func testCanShowAppReview() {
        let defaultsMockRemover = OEXMockUserDefaults().installAsStandardUserDefaults()
        let config = OEXConfig(dictionary: [
            "APP_REVIEWS_ENABLED": true,
            "APP_REVIEW_URI" : "www.test.com"
            ])
        let interface = OEXInterface()
        interface.reachable = true
        let testEnvironment = TestRouterEnvironment(config: config, interface: interface)
        
        XCTAssertTrue(RatingViewController.canShowAppReview(environment: testEnvironment))
        defaultsMockRemover.remove()
    }
    
    func testCanShowAppReviewForAppReviewsDisabled() {
        let defaultsMockRemover = OEXMockUserDefaults().installAsStandardUserDefaults()
        let config = OEXConfig(dictionary: [
            "APP_REVIEWS_ENABLED": false,
            "APP_REVIEW_URI" : "www.test.com"
            ])
        let interface = OEXInterface()
        interface.reachable = true
        let testEnvironment = TestRouterEnvironment(config: config, interface: interface)
        
        XCTAssertFalse(RatingViewController.canShowAppReview(environment: testEnvironment))
        defaultsMockRemover.remove()
    }
    
    func testCanShowAppReviewForNilAppURI() {
        let defaultsMockRemover = OEXMockUserDefaults().installAsStandardUserDefaults()
        let config = OEXConfig(dictionary: [
            "APP_REVIEWS_ENABLED": true,
            ])
        let interface = OEXInterface()
        interface.reachable = true
        let testEnvironment = TestRouterEnvironment(config: config, interface: interface)
        
        XCTAssertFalse(RatingViewController.canShowAppReview(environment: testEnvironment))
        defaultsMockRemover.remove()
    }
    
    func testCanShowAppReviewForPositiveRating() {
        let defaultsMockRemover = OEXMockUserDefaults().installAsStandardUserDefaults()
        let config = OEXConfig(dictionary: [
            "APP_REVIEWS_ENABLED": true,
            "APP_REVIEW_URI" : "www.test.com"
            ])
        let interface = OEXInterface()
        interface.reachable = true
        interface.saveAppVersionWhenLastRated()
        interface.saveAppRating(rating: RatingViewController.minimumPositiveRating)
        let testEnvironment = TestRouterEnvironment(config: config, interface: interface)
        
        XCTAssertFalse(RatingViewController.canShowAppReview(environment: testEnvironment))
        defaultsMockRemover.remove()
    }
    
    func testCanShowAppReviewForNegativeRating() {
        let defaultsMockRemover = OEXMockUserDefaults().installAsStandardUserDefaults()
        let config = OEXConfig(dictionary: [
            "APP_REVIEWS_ENABLED": true,
            "APP_REVIEW_URI" : "www.test.com"
            ])
        let interface = OEXInterface()
        interface.reachable = true
        interface.saveAppRating(rating: RatingViewController.minimumPositiveRating-1)
        interface.saveAppVersionWhenLastRated(version: nil)
        let testEnvironment = TestRouterEnvironment(config: config, interface: interface)
        
        XCTAssertFalse(RatingViewController.canShowAppReview(environment: testEnvironment))
        defaultsMockRemover.remove()
    }
}
