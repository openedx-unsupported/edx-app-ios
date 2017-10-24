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
        let environment = TestRouterEnvironment()
        
        let controller = OEXRegistrationViewController(environment: environment)
        OHHTTPStubs.stubRequests(passingTest: { _ in true}) {request in
            OHHTTPStubsResponse(data: Data(), statusCode: 404, headers: [:])
        }
        controller.t_register(withParameters: [:])

        let event = environment.eventTracker.events[0].asEvent!
        XCTAssertEqual(event.event.category, AnalyticsCategory.Conversion.rawValue)
        XCTAssertEqual(event.event.name, AnalyticsEventName.UserRegistrationClick.rawValue)
    }
    
    func requiredTestField() -> OEXMutableRegistrationFormField {
        let field = OEXMutableRegistrationFormField()
        field.isRequired = true
        return field
    }
    
    func optionalTestField() -> OEXMutableRegistrationFormField {
        let field = OEXMutableRegistrationFormField()
        return field
    }
    
    func testShowOptionalFields() {
        let fields = [self.optionalTestField(),self.requiredTestField()]
        let method = "POST"
        let submitURL = "http://example.com/register"
        let description = OEXRegistrationDescription(fields: fields, method: method, submitURL: submitURL)
        let config = OEXConfig(dictionary:["PLATFORM_NAME" : "App Test"])
        let environment = TestRouterEnvironment(config: config, interface: nil)
        environment.mockNetworkManager.interceptWhenMatching({(_: NetworkRequest<OEXRegistrationDescription>) in true }) {
            
            let parsedThread = description
            return (nil, parsedThread)
        }
        
        let controller = OEXRegistrationViewController(environment: environment)
        _ = controller.view
        waitForStream(controller.t_loaded)
        stepRunLoop()
        XCTAssertEqual(controller.t_visibleFieldCount(), 1)
        controller.t_toggleOptionalFields()
        XCTAssertEqual(controller.t_visibleFieldCount(), 2)
    }

    func testSnapshotContent() {
        let config = OEXConfig(dictionary:["FACEBOOK": [ "ENABLED": true ], "GOOGLE": ["ENABLED": true, "GOOGLE_PLUS_KEY": "FAKE"], "PLATFORM_NAME" : "App Test"])
        let environment = TestRouterEnvironment(config: config, interface: nil)
        let json = JSON(resourceNamed: "RegistrationForm")
        environment.mockNetworkManager.interceptWhenMatching({(_: NetworkRequest<OEXRegistrationDescription>) in true }) {
            
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
