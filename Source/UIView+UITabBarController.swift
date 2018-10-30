//
//  UIView+UITabBarController.swift
//  edX
//
//  Created by Salman on 30/10/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import Foundation

extension UITabBarController {
    func tabBarViewControllerIndex(with controller: AnyClass, courseOutlineMode: CourseOutlineMode? = .full) -> Int {
        guard let viewControllers = viewControllers else {
            return 0
        }
        
        for i in 0..<viewControllers.count {
            if viewControllers[i].isKind(of: controller) {
                if  viewControllers[i].isKind(of: CourseOutlineViewController.self)  {
                    if let viewController = viewControllers[i] as? CourseOutlineViewController, viewController.courseOutlineMode == courseOutlineMode {
                        return i
                    }
                } else {
                    return i
                }
            }
        }
        return 0
    }
}

