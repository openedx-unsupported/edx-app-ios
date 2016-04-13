//
//  SplashScreenInteractor.swift
//  edX
//
//  Created by Akiva Leffert on 3/8/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
import XCTest

class SplashScreenInteractor : FeatureInteractor {
    var container : XCUIElement {
        return otherElements["splash-screen"]
    }

    var registerButton : XCUIElement {
        return buttons["register"]
    }

    var loginButton : XCUIElement {
        return buttons["login"]
    }

    func observeSplashScreen() -> SplashScreenInteractor {
        waitForElement(container)
        XCTAssertTrue(registerButton.exists)
        XCTAssertTrue(loginButton.exists)
        return self
    }

    func navigateToLoginScreen() -> LoginScreenInteractor {
        let loginScreen = LoginScreenInteractor()
        loginButton.tapUntilElementExists(loginScreen.container)
        loginScreen.waitForDisplay()
        return loginScreen
    }

    func navigateToRegisterScreen() -> RegistrationScreenInteractor {
        let registrationScreen = RegistrationScreenInteractor()
        registerButton.tapUntilElementExists(registrationScreen.container)
        registrationScreen.waitForDisplay()
        return registrationScreen
    }
}