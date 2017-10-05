//
//  WhatsNewViewControllerTests.swift
//  edX
//
//  Created by Saeed Bashir on 5/11/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation
@testable import edX

class WhatsNewViewControllerTests: SnapshotTestCase {
    
    func whatsnewController() -> WhatsNewViewController {
        let config = OEXConfig(dictionary:["PLATFORM_NAME" : "Test"])
        let mockEnv = TestRouterEnvironment(config: config, interface: nil)
        let dataModel = WhatsNewDataModel(fileName: "WhatsNew", environment: mockEnv, version: "2.10")
        let controller = WhatsNewViewController(environment: mockEnv, dataModel: dataModel, title: "2.8.1")
        controller.view.setNeedsDisplay()
        
        return controller
    }
    
    func testUIPageControllerInitilization() {
        let controller = whatsnewController()
        XCTAssertNotNil(controller.childViewControllers[0])
    }
    
    func testScreenshot() {
        let controller = whatsnewController()
        inScreenDisplayContext(controller) {
            assertSnapshotValidWithContent(controller)
        }
    }
}
