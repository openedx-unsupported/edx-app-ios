//
//  UIApplication+UIViewController.swift
//  edX
//
//  Created by Salman on 08/11/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

extension UIApplication {

    @objc func topMostController() -> UIViewController?  {
        guard var topController = keyWindow?.rootViewController?.children.first else {
            return keyWindow?.rootViewController
        }
        while true {
            if let presented = topController.presentedViewController {
                topController = presented
            } else if let nav = topController as? UINavigationController {
                topController = nav.visibleViewController ?? topController
            } else if let tab = topController as? UITabBarController {
                topController = tab.selectedViewController ?? topController
            } else {
                break
            }
        }
        
        return topController
    }
    
    var isPreferredContentSizeCategoryLarge: Bool {
        let preferredContentSize = UIApplication.shared.preferredContentSizeCategory.rawValue
        return ((preferredContentSize == "UICTContentSizeCategoryXL") ||
            (preferredContentSize == "UICTContentSizeCategoryXXL") ||
            (preferredContentSize == "UICTContentSizeCategoryXXXL") ||
            (preferredContentSize == "UICTContentSizeCategoryAccessibilityXL") ||
            (preferredContentSize == "UICTContentSizeCategoryAccessibilityXXL") ||
            (preferredContentSize == "UICTContentSizeCategoryAccessibilityXXXL"))
    }
}
