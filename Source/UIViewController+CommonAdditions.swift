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
        // In case of iPad vertical size class is always regular for both height and width
        if UIDevice.current.userInterfaceIdiom == .pad && UIDevice.current.orientation.isLandscape {
            return true
        }
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
        return (navigationController?.viewControllers.index(of: self) == 0) &&
            (presentingViewController?.presentedViewController == self
            || isRootModal()
            || tabBarController?.presentingViewController is UITabBarController)
    }
    
    func isRootModal() -> Bool {
        return (navigationController != nil && navigationController?.presentingViewController?.presentedViewController == navigationController)
    }
    
    func configurePresentationController(withSourceView sourceView: UIView) {
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            popoverPresentationController?.sourceView = sourceView
            popoverPresentationController?.sourceRect = sourceView.bounds
        }
    }
}
