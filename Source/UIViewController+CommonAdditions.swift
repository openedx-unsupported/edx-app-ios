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
/*
    //TODO: This method need to return the top most VC  even if the base is simple UIViewController
    @objc func topMostController() -> UIViewController? {
        var topController = UIApplication.shared.keyWindow?.rootViewController
        while true {
            if let presented = topController?.presentedViewController {
                topController = presented
            } else if let nav = topController as? UINavigationController {
                topController = nav.visibleViewController
            } else if let tab = topController as? UITabBarController {
                topController = tab.selectedViewController
            } else {
                break
            }
        }
        
        return topController
    }
    */
    @objc func topMostController() -> UIViewController?  {
        guard var topController = UIApplication.shared.keyWindow?.rootViewController?.childViewControllers.first else {
            return nil
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
    
    func baseViewController() -> UIViewController? {
        guard var topViewController = self.parent else {
            return nil
        }
        while true {
            if let presented = topViewController.presentedViewController {
                topViewController = presented
            } else if let nav = topViewController as? UINavigationController {
                topViewController = nav.visibleViewController ?? topViewController
            } else if let tab = topViewController as? UITabBarController {
                topViewController = tab.selectedViewController ?? topViewController
            } else {
                break
            }
        }
        
        return topViewController
    }
    
    func isModal() -> Bool {
        return (navigationController?.viewControllers.index(of: self) == 0) &&
            (presentingViewController?.presentedViewController == self
            || isRootModal()
            || tabBarController?.presentingViewController is UITabBarController)
            || self is UIActivityViewController
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
