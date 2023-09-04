//
//  UIView+UIViewControllerTests.swift
//  edX
//
//  Created by Saeed Bashir on 7/15/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
@testable import edX

class UIView_UIViewControllerTests: XCTestCase {
    func testParentController() {
        let controller = UIViewController()
        let view = UIView()
        controller.view.addSubview(view)
        XCTAssertNotNil(view.firstAvailableUIViewController())
    }
    
    func testNoParentController() {
        let view = UIView()
        XCTAssertNil(view.firstAvailableUIViewController())
    }
}