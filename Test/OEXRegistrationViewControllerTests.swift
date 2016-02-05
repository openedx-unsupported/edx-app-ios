//
//  OEXRegistrationViewControllerTests.swift
//  edX
//
//  Created by Akiva Leffert on 2/5/16.
//  Copyright © 2016 edX. All rights reserved.
//

import XCTest
import edX

class OEXRegistrationViewControllerTests: XCTestCase {

    func testAnalyticsEmitted() {
        let baseEnvironment = TestRouterEnvironment()
        let environment = OEXRegistrationViewControllerEnvironment(analytics: baseEnvironment.analytics, config: baseEnvironment.config, router: baseEnvironment.router)
        let controller = OEXRegistrationViewController(environment: environment)
        OHHTTPStubs.stubRequestsPassingTest({ _ in true}) {request in
            OHHTTPStubsResponse(data: NSData(), statusCode: 404, headers: [:])
        }
        controller.t_registerWithParameters([:])

        let event = baseEnvironment.eventTracker.events[0].asEvent!
        XCTAssertEqual(event.event.category, OEXAnalyticsCategoryConversion)
        XCTAssertEqual(event.event.name, OEXAnalyticsEventRegistration)
    }
}
