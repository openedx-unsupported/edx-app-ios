//
//  TabBarItem.swift
//  edX
//
//  Created by Salman on 26/12/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

public protocol ScrollViewControllerDelegateProvider {
    var scrollViewDelegate: ScrollableViewControllerDelegate? { get set }
}

@objc public protocol ScrollableViewControllerDelegate: AnyObject {
    func scrollViewDidScroll(scrollView: UIScrollView)
}

// TabBarItem represent each tab in tabBarViewController
struct TabBarItem {
    let title: String
    let viewController: UIViewController
    let icon: Icon
    let detailText: String
}

extension TabBarItem: Equatable {
    static func == (lhs: TabBarItem, rhs: TabBarItem) -> Bool {
        lhs.title == rhs.title
    }
}
