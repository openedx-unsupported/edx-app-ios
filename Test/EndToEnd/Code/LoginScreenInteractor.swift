//
//  LoginScreenInteractor.swift
//  edX
//
//  Created by Akiva Leffert on 3/8/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
import XCTest
import edXCore


class LoginScreenInteractor : FeatureInteractor {
    var container : XCUIElement {
        return otherElements["login-screen"]
    }

    var usernameField: XCUIElement {
        return textFields["user-field"]
    }

    var passwordField: XCUIElement {
        return secureTextFields["password-field"]
    }

    var signInButton: XCUIElement {
        return buttons["sign-in-button"]
    }

    func waitForDisplay() {
        waitForElement(container)
    }

    func login(_ credentials: TestCredentials) -> EnrolledCoursesInteractor {
        usernameField.clearAndEnterText(credentials.username)
        passwordField.clearAndEnterText(credentials.password)
        signInButton.tap()
        return EnrolledCoursesInteractor()
    }
    
}
