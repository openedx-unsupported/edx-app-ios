//
//  FindCoursesInteractor.swift
//  edX
//
//  Created by Saeed Bashir on 4/12/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
import XCTest
@testable import edX

class FindCoursesInteractor: FeatureInteractor {
    
    var container: XCUIElement {
        return find(identifier: "course-catalog-screen")
    }
    
    func waitForDisplay() {
        waitForElement(container)
    }
    
    var coursesTableView: XCUIElement {
        return find(identifier: "courses-table-view")
    }
    
    var coursesWebView: XCUIElement {
        return find(identifier: "find-courses-webview")
    }
    
    func verifyFindCoursesLoaded () {
        
        let config = OEXConfig(bundle: Bundle(for: FindCoursesInteractor.self))
     
        switch config.courseEnrollmentConfig.type {
        case .Native, .None:
            waitForElement(coursesTableView.cells.element(boundBy: 0))
            
        case .Webview:
            waitForElementNonNullValue(coursesWebView)
        }
    }
}
