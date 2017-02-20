//
//  OEXRearTableViewControllerTests.swift
//  edX
//
//  Created by Akiva Leffert on 2/16/16.
//  Copyright © 2016 edX. All rights reserved.
//

import XCTest

@testable import edX

class EmailTemplateTests: XCTestCase {

    func testSubmitFeedbackContent() {
        let body = EmailTemplates.supportEmailMessageTemplate()
        XCTAssertTrue(body.containsString(Strings.SubmitFeedback.deviceModel(model: UIDevice.currentDevice().model)))
        XCTAssertTrue(body.containsString(Strings.SubmitFeedback.osVersion(version: UIDevice.currentDevice().systemVersion)))
        XCTAssertTrue(body.containsString(Strings.SubmitFeedback.appVersion(version: NSBundle.mainBundle().oex_shortVersionString(), build: NSBundle.mainBundle().oex_buildVersionString())))
    }

}
