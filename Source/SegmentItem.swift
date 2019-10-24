//
//  SegmentItem.swift
//  edX
//
//  Created by Salman on 30/01/2019.
//  Copyright © 2019 edX. All rights reserved.
//

import UIKit

// SegmentItem represent each tab in UISegmentedControl
struct SegmentItem {
    let title: String
    let viewController: UIViewController
    let index: Int
    let type: Int
    let analyticsScreenName: String
}
