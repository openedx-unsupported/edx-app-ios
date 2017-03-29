//
//  FeatureTestCase.swift
//  edX
//
//  Created by Akiva Leffert on 3/8/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
import XCTest


/// Base class for
class FeatureTestCase : XCTestCase {
    static var activeTest : XCTestCase!

    override func setUp() {
        super.setUp()
        FeatureTestCase.activeTest = self
    }

    override func tearDown() {
        super.setUp()
        FeatureTestCase.activeTest = nil
        XCUIApplication().terminate()
    }
}

/// Extension making it easy to wait for an element outside the methods of an XCTestCase
/// Requires the current test to be a subclass of FeatureTestCase
protocol FeatureInteractor {}
extension FeatureInteractor {
    func waitForElement(_ element: XCUIElement, predicate: NSPredicate = NSPredicate(format: "exists == true"), file: String = #file, line: UInt = #line) {
        
        FeatureTestCase.activeTest.expectation(for: predicate, evaluatedWith: element, handler: nil)
        FeatureTestCase.activeTest.waitForExpectations { (error) -> Void in
            if error != nil {
                FeatureTestCase.activeTest.recordFailure(withDescription: "Timeout waiting for element: \(element)", inFile: file, atLine: line, expected: true)
            }
        }
    }
    
    func waitForElementNonNullValue(_ element: XCUIElement, file: String = #file, line: UInt = #line) {
        waitForElement(element, predicate: NSPredicate(format: "value != nil"), file: file, line: line)
    }

    // helpers
    var buttons: XCUIElementQuery { return XCUIApplication().buttons }
    var otherElements: XCUIElementQuery { return XCUIApplication().otherElements }
    var textFields: XCUIElementQuery { return XCUIApplication().textFields }
    var secureTextFields: XCUIElementQuery { return XCUIApplication().secureTextFields }

    func find(identifier: String, type: XCUIElementType = .any) -> XCUIElement {
        return XCUIApplication().descendants(matching: type)[identifier]
    }

    func pickerWheel(identifier: String, index: UInt = 0) -> XCUIElement {
        // You can't actually manipulate the "picker" itself. You have to manipulate the individual wheel. 
        // However, the wheel doesn't have a direct name, so you have to access it by index, even if there's only one wheel.
        return find(identifier: identifier, type: .picker).descendants(matching: .pickerWheel).element(boundBy: index)
    }
}

extension XCUIElement : FeatureInteractor {}

