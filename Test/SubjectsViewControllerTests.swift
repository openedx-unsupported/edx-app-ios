//
//  SubjectsViewControllerTests.swift
//  edXTests
//
//  Created by Zeeshan Arif on 5/28/18.
//  Copyright © 2018 edX. All rights reserved.
//

@testable import edX

class SubjectsViewControllerTests: SnapshotTestCase {
    
    func testScreenshot() {
        let controller = SubjectsViewController()
        
        inScreenNavigationContext(controller) {
            assertSnapshotValidWithContent(controller.navigationController!)
        }
    }
    
}
