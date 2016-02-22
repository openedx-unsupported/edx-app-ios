//
//  ContainerNavigationController.swift
//  edX
//
//  Created by Akiva Leffert on 6/29/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

/// A controller should implement this protocol to indicate that it wants to be responsible
/// for its own status bar styling instead of leaving it up to its container, which is the default
/// behavior.
/// It is deliberately empty and just exists so controllers can declare they want this behavior.
@objc protocol ContainedNavigationController {
}

/// A simple UINavigationController subclass that can forward status bar
/// queries to its children should they opt into that by implementing the ContainedNavigationController protocol
class ForwardingNavigationController: UINavigationController {
    override func childViewControllerForStatusBarStyle() -> UIViewController? {
        if let controller = viewControllers.last as? ContainedNavigationController as? UIViewController {
            return controller
        }
        else {
            return super.childViewControllerForStatusBarStyle()
        }
    }
    
    override func childViewControllerForStatusBarHidden() -> UIViewController? {
        if let controller = viewControllers.last as? ContainedNavigationController as? UIViewController {
            return controller
        }
        else {
            return super.childViewControllerForStatusBarHidden()
        }
        
    }
    
    override func shouldAutorotate() -> Bool {
        if let controller = viewControllers.last as? ContainedNavigationController as? UIViewController {
            return controller.shouldAutorotate()
        }
        else {
            return false
        }
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if let controller = viewControllers.last as? ContainedNavigationController as? UIViewController {
            return controller.supportedInterfaceOrientations()
        }
        else {
            return .Portrait
        }
    }
    
    override func preferredInterfaceOrientationForPresentation() -> UIInterfaceOrientation {
        if let controller = viewControllers.last as? ContainedNavigationController as? UIViewController {
            return controller.preferredInterfaceOrientationForPresentation()
        }
        else {
            return .Portrait
        }
    }
}
