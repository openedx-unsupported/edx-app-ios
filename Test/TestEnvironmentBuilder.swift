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
        
        OEXStyles.setShared(OEXStyles())
        OEXStyles.shared().applyGlobalAppearance()

        OEXFileUtility.routeUserDataToTempPath()
        
        OHHTTPStubs.stubRequests(passingTest: { (request) -> Bool in
            return true
        }, withStubResponse: { (request) -> OHHTTPStubsResponse in
            assert(true, "Attempting network request during test")
            return OHHTTPStubsResponse(error: NSError.oex_unknownError())
        })
    }
}
