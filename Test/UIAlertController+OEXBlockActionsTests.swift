//
//  UIAlertController+OEXBlockActionsTests.swift
//  edX
//
//  Created by Danial Zahid on 8/31/16.
//  Copyright © 2016 edX. All rights reserved.
//

import XCTest
@testable import edX

class UIAlertController_OEXBlockActionsTests: XCTestCase {
    
    func testAlertController() {
        let controller = UIViewController()
        let alert = UIAlertController().showIn(viewController: controller, title: "Test Title", message: "Test Message",preferredStyle: UIAlertControllerStyle.alert, cancelButtonTitle: "Cancel", destructiveButtonTitle: "Delete", otherButtonsTitle: ["Button 1","Button 2"], tapBlock: nil)
        XCTAssertNotNil(alert)
        XCTAssertEqual(alert.actions.count, 4)
    }
    
    func testErrorAlertController() {
        let controller = UIViewController()
        let alert = UIAlertController().showAlert(withTitle: "Error Title", message: "Error Message", onViewController: controller)
        XCTAssertNotNil(alert)
        XCTAssertEqual(alert.actions.count, 1)
        XCTAssertEqual(alert.actions.first?.title, Strings.ok)
    }

}
