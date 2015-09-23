//
//  TestEnvironmentBuilder.swift
//  edX
//
//  Created by Akiva Leffert on 6/4/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

@objc(TestEnvironmentBuilder)
class TestEnvironmentBuilder: NSObject {
    
    override init() {
        super.init()
        // TODO remove this once the new navigation is done
        OEXConfig.setSharedConfig(OEXConfig(dictionary: ["NEW_COURSE_NAVIGATION_ENABLED" : true]))
        
        OEXStyles.setSharedStyles(OEXStyles())
        OEXStyles.sharedStyles().applyGlobalAppearance()
        
        OHHTTPStubs.stubRequestsPassingTest({ (request) -> Bool in
            return true
        }, withStubResponse: { (request) -> OHHTTPStubsResponse in
            assert(true, "Attempting network request during test")
            return OHHTTPStubsResponse(error: NSError.oex_unknownError())
        })
    }
    
    static func test() {
        print("\(self)")
    }
}