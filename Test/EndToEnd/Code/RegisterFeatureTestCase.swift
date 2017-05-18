//
//  RegisterFeatureTestCase.swift
//  edX
//
//  Created by Akiva Leffert on 3/15/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

class RegisterFeatureTestCase : FeatureTestCase {
    func testRegisterUsernamePassword() {
        let credentials = TestCredentials(type: .fresh)

        AppInteractor()
            .launchApp()
            .observeSplashScreen()
            .navigateToRegisterScreen()
            .enterValues(values: [
                "username": .text(credentials.username),
                "password": .text(credentials.password),
                "email": .text(credentials.email),
                "name": .text("Test Person"),
                "country": .picker("Antarctica")
                ])
            .register()
            .observeEnrolledCoursesScreen()
    }
}
