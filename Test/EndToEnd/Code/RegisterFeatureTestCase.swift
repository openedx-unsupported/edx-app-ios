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
        let credentials = TestCredentials(type: .Fresh)

        AppInteractor()
            .launchApp()
            .observeSplashScreen()
            .navigateToRegisterScreen()
            .enterValues(values: [
                "username": .Text(credentials.username),
                "password": .Text(credentials.password),
                "email": .Text(credentials.email),
                "name": .Text("Test Person"),
                "country": .Picker("Antarctica")
                ])
            .register()
            .observeEnrolledCoursesScreen()
    }
}