//
//  ScrollableDelegate.swift
//  edX
//
//  Created by MuhammadUmer on 01/02/2023.
//  Copyright © 2023 edX. All rights reserved.
//

import Foundation

public protocol ScrollableDelegateProvider {
    var scrollableDelegate: ScrollableDelegate? { get set }
}

@objc public protocol ScrollableDelegate: AnyObject {
    func scrollViewDidScroll(scrollView: UIScrollView)
}
