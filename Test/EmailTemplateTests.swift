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
        XCTAssertTrue(body.contains(Strings.SubmitFeedback.deviceModel(model: UIDevice.current.model)))
        XCTAssertTrue(body.contains(Strings.SubmitFeedback.osVersion(version: UIDevice.current.systemVersion)))
        XCTAssertTrue(body.contains(Strings.SubmitFeedback.appVersion(version: Bundle.main.oex_shortVersionString(), build: Bundle.main.oex_buildVersionString())))
    }

}
