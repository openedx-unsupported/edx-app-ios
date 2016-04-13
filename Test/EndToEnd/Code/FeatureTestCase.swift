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
    func waitForElement(element : XCUIElement, findByValue:Bool = false, file: String = #file, line: UInt = #line) {
        var predicate:NSPredicate
        
        findByValue ? (predicate = NSPredicate(format: "value != nil")) : (predicate = NSPredicate(format: "exists == true"))
        
        FeatureTestCase.activeTest.expectationForPredicate(predicate, evaluatedWithObject: element, handler: nil)
        FeatureTestCase.activeTest.waitForExpectations { (error) -> Void in
            if error != nil {
                FeatureTestCase.activeTest.recordFailureWithDescription("Timeout waiting for element: \(element)", inFile: file, atLine: line, expected: true)
            }
        }
    }

    // helpers
    var buttons: XCUIElementQuery { return XCUIApplication().buttons }
    var otherElements: XCUIElementQuery { return XCUIApplication().otherElements }
    var textFields: XCUIElementQuery { return XCUIApplication().textFields }
    var secureTextFields: XCUIElementQuery { return XCUIApplication().secureTextFields }

    func find(identifier identifier: String, type: XCUIElementType = .Any) -> XCUIElement {
        return XCUIApplication().descendantsMatchingType(type)[identifier]
    }

    func pickerWheel(identifier identifier: String, index: UInt = 0) -> XCUIElement {
        // You can't actually manipulate the "picker" itself. You have to manipulate the individual wheel. 
        // However, the wheel doesn't have a direct name, so you have to access it by index, even if there's only one wheel.
        return find(identifier: identifier, type: .Picker).descendantsMatchingType(.PickerWheel).elementBoundByIndex(index)
    }
}

extension XCUIElement : FeatureInteractor {}

