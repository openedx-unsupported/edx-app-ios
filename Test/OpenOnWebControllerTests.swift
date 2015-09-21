//
//  OpenOnWebControllerTests.swift
//  edX
//
//  Created by Akiva Leffert on 6/25/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import edX
import XCTest
import UIKit

class OpenOnWebControllerTests: XCTestCase {
    class WebControllerDelegate : OpenOnWebControllerDelegate {
        func presentationControllerForOpenOnWebController(controller: OpenOnWebController) -> UIViewController {
            return UIViewController()
        }
    }
    
    private func sampleInfo(URL URL: NSURL? = NSURL(string: "http://example.com")) -> OpenOnWebController.Info {
        return OpenOnWebController.Info(
            courseID: "1234",
            blockID: "456",
            supported: false,
            URL: URL)
    }
    
    func testButtonEnabledWithURL() {
        let delegate = WebControllerDelegate()
        let controller = OpenOnWebController(delegate: delegate)
        XCTAssertFalse(controller.barButtonItem.enabled)
        
        controller.info = sampleInfo()
        XCTAssertTrue(controller.barButtonItem.enabled)
        XCTAssertTrue(controller.barButtonItem.hasTapAction)
    }
    
    func testButtonEnabledWithoutURL() {
        let delegate = WebControllerDelegate()
        let controller = OpenOnWebController(delegate: delegate)
        controller.info = sampleInfo(URL: nil)
        XCTAssertFalse(controller.barButtonItem.enabled)
    }
}
