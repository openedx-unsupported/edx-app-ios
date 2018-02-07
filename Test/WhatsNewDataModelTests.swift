//
//  WhatsNewDataModelTests.swift
//  edX
//
//  Created by Saeed Bashir on 5/11/17.
//  Copyright © 2017 edX. All rights reserved.
//

@testable import edX

// In WhatsNew.json testing json file has 'platform_name' at the place of 'App Test'
private let testMessage = "We would love to hear your feedback so now we ask you about how you would rate the App Test app."

class WhatsNewDataModelTests: XCTestCase {
    func testParsing() {
        let config = OEXConfig(dictionary:["PLATFORM_NAME" : "App Test"])
        let mockEnv = TestRouterEnvironment(config: config, interface: nil)
        let dataModel = WhatsNewDataModel(fileName: "WhatsNew", environment: mockEnv, version: "2.10")
        
        XCTAssertNotNil(dataModel.fields)
        XCTAssertEqual(dataModel.fields?.count, 4) // 4 items are for iOS in test json 'WhatsNew.json'
        
        // Test whatsNew items parsing
        
        let item = dataModel.fields?.first
        let secondItem = dataModel.fields?[1]
        // In WhatsNew.json first two items has same title & message. But itemID makes the difference and make both items unique.
        XCTAssertNotEqual(item, secondItem)
        XCTAssertNotNil(item)
        XCTAssertNotNil(item?.image)
        XCTAssertNotNil(item?.title)
        XCTAssertNotNil(item?.message)
        
        // Test platform name injection for placeholder 'platform_name'
        XCTAssertEqual(item?.message, testMessage)
    }
    
}
