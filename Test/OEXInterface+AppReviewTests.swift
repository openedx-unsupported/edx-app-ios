//
//  OEXInterface+AppReviewsTests.swift
//  edX
//
//  Created by Danial Zahid on 2/20/17.
//  Copyright © 2017 edX. All rights reserved.
//

import XCTest
@testable import edX

class OEXInterface_AppReviewTests: XCTestCase {
    
    let interface = OEXInterface()
    var defaultsMockRemover : OEXRemovable!
    
    override func setUp() {
        defaultsMockRemover = OEXMockUserDefaults().installAsStandardUserDefaults()
    }
    
    override func tearDown() {
        defaultsMockRemover.remove()
    }
    
    func testUnassignedAppRating() {
        XCTAssertEqual(interface.getSavedAppRating(), 0)
    }
    
    func testUnassignedAppVersion() {
        XCTAssertNil(interface.getSavedAppVersionWhenLastRated())
    }
    
    func testAppRating() {
        interface.saveAppRating(rating: 3)
        XCTAssertEqual(interface.getSavedAppRating(), 3)
    }
    
    func testDefaultAppVersion() {
        interface.saveAppVersionWhenLastRated()
        XCTAssertEqual(interface.getSavedAppVersionWhenLastRated(), Bundle.main.oex_buildVersionString())
    }
    
    func testCustomAppVersion() {
        interface.saveAppVersionWhenLastRated(version: "2.6.1")
        XCTAssertEqual(interface.getSavedAppVersionWhenLastRated(), "2.6.1")
    }
    
}
