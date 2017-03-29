//
//  RegistrationScreenInteractor.swift
//  edX
//
//  Created by Akiva Leffert on 3/15/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
import XCTest

enum FormItem {
    case text(String)
    case picker(String)
}

class RegistrationScreenInteractor : FeatureInteractor {
    var container: XCUIElement {
        return otherElements["registration-screen"]
    }

    func waitForDisplay() {
        waitForElement(container)
    }

    var registerButton : XCUIElement {
        return buttons["register"]
    }

    func enterValues(values: [String:FormItem]) -> RegistrationScreenInteractor {
        for (key, value) in values {
            let element = find(identifier: "field-" + key)
            switch value {
            case let .text(content):
                element.clearAndEnterText(content)
            case let .picker(content):
                element.tap()
                let picker = pickerWheel(identifier: "picker-field-" + key)
                picker.adjust(toPickerWheelValue: content)
            }
        }
        return self
    }

    func register() -> EnrolledCoursesInteractor {
        let element = registerButton
        element.tap()
        
        return EnrolledCoursesInteractor()
    }
}
