//
//  TabContainerViewTests.swift
//  edX
//
//  Created by Akiva Leffert on 4/5/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
import XCTest

@testable import edX

class TabContainerViewTests : XCTestCase {

    var testItems : (TabItem, TabItem) = (
        TabItem(name: "Name", view: UIView(), identifier: "item1"),
        TabItem(name: "Name", view: UIView(), identifier: "item2")
    )

    func testSettingItemsChoosesFirstItem() {
        let tabView = TabContainerView()

        let (firstItem, secondItem) = testItems
        tabView.items = [firstItem, secondItem]

        XCTAssertTrue(tabView.t_isShowingView(forItem: firstItem))
    }

    func testSettingEmptyItemsClears() {
        let tabView = TabContainerView()

        let (firstItem, secondItem) = testItems
        tabView.items = [firstItem, secondItem]
        XCTAssertTrue(tabView.t_isShowingView(forItem: firstItem))

        tabView.items = []
        XCTAssertTrue(!tabView.t_isShowingView(forItem: firstItem))
    }

    func testSwitchingTabs() {
        let tabView = TabContainerView()

        let (firstItem, secondItem) = testItems
        tabView.items = [firstItem, secondItem]
        XCTAssertTrue(tabView.t_isShowingView(forItem: firstItem))

        tabView.showTab(withIdentifier: secondItem.identifier)
        XCTAssertTrue(tabView.t_isShowingView(forItem: secondItem))

        tabView.showTab(withIdentifier: firstItem.identifier)
        XCTAssertTrue(tabView.t_isShowingView(forItem: firstItem))
    }
}
