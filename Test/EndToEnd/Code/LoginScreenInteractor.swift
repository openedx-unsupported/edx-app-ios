//
//  LoginScreenInteractor.swift
//  edX
//
//  Created by Akiva Leffert on 3/8/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
import XCTest


struct Credentials {
    let username : String
    let password: String
}

enum CredentialType {
    case Fresh // Credentials without an existing account
    case Default // Standard test credentials. Have an account and registered for at least one course
}

private class TestCredentialManager {

    private static let shared = TestCredentialManager()

    private let config = EndToEndConfig()

    private func freshCredentials() -> Credentials {
        let password = NSUUID().UUIDString
        let username = config.emailTemplate.oex_formatWithParameters(["unique_id": NSUUID().UUIDString])
        return Credentials(username : username, password: password)
    }

    lazy var defaultCredentials: Credentials = {
        let credentials = self.freshCredentials()
        self.registerUser(credentials)
        return credentials
    }()

    func registerUser(credentials: Credentials) {
    }
}

class TestCredentials {
    let username : String
    let password : String

    init(type: CredentialType = .Default) {
        let credentials: Credentials
        switch type {
        case .Fresh:
            credentials = TestCredentialManager.shared.freshCredentials()
        case .Default:
            credentials = TestCredentialManager.shared.defaultCredentials
        }

        username = credentials.username
        password = credentials.password
    }
}

class LoginScreenInteractor : FeatureInteractor {
    var container : XCUIElement {
        return XCUIApplication().otherElements["login-screen"]
    }

    var usernameField: XCUIElement {
        return XCUIApplication().textFields["user-field"]
    }

    var passwordField: XCUIElement {
        return XCUIApplication().secureTextFields["password-field"]
    }

    var signInButton: XCUIElement {
        return XCUIApplication().buttons["sign-in-button"]
    }

    func waitForDisplay() {
        waitForElement(container)
    }

    func login(credentials: TestCredentials) -> EnrolledCoursesInteractor {
        usernameField.clearAndEnterText(credentials.username)
        passwordField.clearAndEnterText(credentials.password)
        signInButton.tap()
        return EnrolledCoursesInteractor()
    }
}