//
//  NavigationDrawerInteractor.swift
//  edX
//
//  Created by Saeed Bashir on 4/12/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
import XCTest

class NavigationDrawerInteractor: FeatureInteractor {

    fileprivate var container: XCUIElement {
        return find(identifier: "navigation-drawer")
    }
    
    fileprivate var findCoursesItem: XCUIElement {
        return find(identifier: "find-courses-cell")
    }
    
    func waitForDisplay() {
        waitForElement(container)
    }
    
    func showFindCoursesScreen() -> FindCoursesInteractor {
        findCoursesItem.tap()
        
        let findCoursesScreen = FindCoursesInteractor()
        findCoursesScreen.waitForDisplay()
        return findCoursesScreen
    }
}
