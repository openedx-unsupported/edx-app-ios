//
//  EnrolledCoursesInteractor.swift
//  edX
//
//  Created by Akiva Leffert on 3/8/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
import XCTest

class EnrolledCoursesInteractor : FeatureInteractor {
    var container : XCUIElement {
        return otherElements["enrolled-courses-screen"]
    }

    func observeEnrolledCoursesScreen() {
        waitForElement(container)
    }
}