//
//  AppInteractor.swift
//  edX
//
//  Created by Akiva Leffert on 3/8/16.
//  Copyright © 2016 edX. All rights reserved.
//

import XCTest

class AppInteractor {
    func launchApp() -> AppLaunchInteractor {
        let application = XCUIApplication()
        application.launchArguments = ["-AppleLocale", "en_US", "-END_TO_END_TEST"]
        application.launch()
        return AppLaunchInteractor()
    }
}