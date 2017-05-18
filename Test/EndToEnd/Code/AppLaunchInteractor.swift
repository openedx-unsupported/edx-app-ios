//
//  AppLaunchInteractor.swift
//  edX
//
//  Created by Akiva Leffert on 3/8/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
import XCTest

open class AppLaunchInteractor {

    // Anonymous users should land here
    func observeSplashScreen() -> SplashScreenInteractor {
        return SplashScreenInteractor().observeSplashScreen()
    }
}
