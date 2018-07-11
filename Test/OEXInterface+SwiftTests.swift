//
//  OEXInterface+SwiftTests.swift
//  edXTests
//
//  Created by Jose Antonio Gonzalez on 2018/07/11.
//  Copyright © 2018 edX. All rights reserved.
//

import XCTest

class OEXInterface_SwiftTests: XCTestCase {
    
    let interface = OEXInterface()
    let config = OEXConfig()
    var defaultsMockRemover : OEXRemovable!
    
    override func setUp() {
        defaultsMockRemover = OEXMockUserDefaults().installAsStandardUserDefaults()
    }
    
    override func tearDown() {
        defaultsMockRemover.remove()
    }
    
    func testEnrollmentUrl() {
        let URLString : NSMutableString = OEXConfig.shared().apiHostURL()?.absoluteString as! NSMutableString
        XCTAssertNil(interface.formatEnrollmentURL(with: URLString))
    }
}
