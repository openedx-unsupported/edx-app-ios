//
//  UIApplication+UIViewController.swift
//  edX
//
//  Created by Salman on 08/11/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

extension UIApplication {
    
    @objc var window: UIWindow? {
        if Thread.isMainThread {
            return UIApplication
                .shared
                .connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first { $0.isKeyWindow }
        } else {
            var win: UIWindow?
            DispatchQueue.main.sync {
                win = UIApplication
                    .shared
                    .connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .first { $0.isKeyWindow }
            }
            
            return win
        }
    }
         
    var interfaceOrientation: UIInterfaceOrientation {
        if Thread.isMainThread {
            return window?.windowScene?.interfaceOrientation ?? .portrait
        } else {
            var orientation: UIInterfaceOrientation?
            DispatchQueue.main.sync {
                orientation = window?.windowScene?.interfaceOrientation ?? .portrait
            }
            return orientation ?? .portrait
        }
    }

    @objc func topMostController() -> UIViewController?  {
        guard var topController = window?.rootViewController?.children.first else {
            return window?.rootViewController
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
