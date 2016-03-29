//
//  LoginFeatureTestCase.swift
//  edX
//
//  Created by Akiva Leffert on 3/5/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
import XCTest

class LoginFeatureTestCase : FeatureTestCase {

    func testLoginWithUsernamePassword() {
        AppInteractor()
            .launchApp()
            .observeSplashScreen()
            .navigateToLoginScreen()
            .login(TestCredentials())
            .observeEnrolledCoursesScreen()
    }
}