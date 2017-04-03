//
//  UIViewController+CommonAditions.swift
//  edX
//
//  Created by Saeed Bashir on 8/4/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

extension UIViewController {
    func isVerticallyCompact() -> Bool {
        return self.traitCollection.verticalSizeClass == .compact
    }
    
    func currentOrientation() -> UIInterfaceOrientation {
        return UIApplication.shared.statusBarOrientation
    }

    func topMostController() -> UIViewController? {
        var topController = UIApplication.shared.keyWindow?.rootViewController
        while ((topController?.presentedViewController) != nil) {
            topController = topController?.presentedViewController
        }
        
        return topController
    }
    
    func isModal() -> Bool {
        return self.presentingViewController?.presentedViewController == self
            || (self.navigationController != nil && self.navigationController?.presentingViewController?.presentedViewController == self.navigationController)
            || self.tabBarController?.presentingViewController is UITabBarController
    }
}
