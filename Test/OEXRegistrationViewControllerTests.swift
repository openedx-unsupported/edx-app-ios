//
//  OEXRegistrationViewControllerTests.swift
//  edX
//
//  Created by Akiva Leffert on 2/5/16.
//  Copyright © 2016 edX. All rights reserved.
//

import XCTest
@testable import edX

class OEXRegistrationViewControllerTests: SnapshotTestCase {

    func testAnalyticsEmitted() {
        let baseEnvironment = TestRouterEnvironment()
        let environment = OEXRegistrationViewControllerEnvironment(analytics: baseEnvironment.analytics, config: baseEnvironment.config, networkManager: baseEnvironment.mockNetworkManager, router: baseEnvironment.router)
        let controller = OEXRegistrationViewController(environment: environment)
        OHHTTPStubs.stubRequestsPassingTest({ _ in true}) {request in
            OHHTTPStubsResponse(data: NSData(), statusCode: 404, headers: [:])
        }
        controller.t_registerWithParameters([:])

        let event = baseEnvironment.eventTracker.events[0].asEvent!
        XCTAssertEqual(event.event.category, AnalyticsCategory.Conversion.rawValue)
        XCTAssertEqual(event.event.name, AnalyticsEventName.UserRegistration.rawValue)
    }

    func testSnapshotContent() {
        let baseEnvironment = TestRouterEnvironment()
        let config = OEXConfig(dictionary:["FACEBOOK": [ "ENABLED": true ], "GOOGLE": ["ENABLED": true, "GOOGLE_PLUS_KEY": "FAKE"], "PLATFORM_NAME" : "App Test"])
        let environment = OEXRegistrationViewControllerEnvironment(analytics: OEXAnalytics(), config: config, networkManager: baseEnvironment.mockNetworkManager, router: nil)
        let json = JSON(resourceNamed: "RegistrationForm")
        baseEnvironment.mockNetworkManager.interceptWhenMatching({(_: NetworkRequest<OEXRegistrationDescription>) in true }) {
            
            let parsedThread = json.dictionaryObject.map { OEXRegistrationDescription(dictionary: $0) }
            return (nil, parsedThread!)
        }
        
        let controller = OEXRegistrationViewController(environment: environment)
        inScreenNavigationContext(controller) {
            waitForStream(controller.t_loaded)
            stepRunLoop()
            assertSnapshotValidWithContent(controller.navigationController!)
        }
    }

}
