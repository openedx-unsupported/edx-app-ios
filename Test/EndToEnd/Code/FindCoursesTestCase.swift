//
//  FindCoursesTestCase.swift
//  edX
//
//  Created by Saeed Bashir on 4/12/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

class FindCoursesTestCase: FeatureTestCase {
    func testFindCourses() {
        AppInteractor()
            .launchApp()
            .observeSplashScreen()
            .navigateToLoginScreen()
            .login(TestCredentials())
            .openNavigationDrawer()
            .showFindCoursesScreen()
            .verifyFindCoursesLoaded()
    }
}