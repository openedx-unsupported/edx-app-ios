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
        let controller = SubjectsViewController(environment: TestRouterEnvironment())
        controller.view.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height)
        controller.refreshLayout()
        inScreenNavigationContext(controller) {
            assertSnapshotValidWithContent(controller.navigationController!)
        }
    }
    
}
