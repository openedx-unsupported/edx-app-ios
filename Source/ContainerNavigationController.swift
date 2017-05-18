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
protocol StatusBarOverriding {
}

/// A controller should implement this protocol to indicate that it wants to be responsible
/// for its own interface orientation instead of using the defaults.
/// It is deliberately empty and just exists so controllers can declare they want this behavior.
@objc protocol InterfaceOrientationOverriding {
}

/// A simple UINavigationController subclass that can forward status bar
/// queries to its children should they opt into that by implementing the ContainedNavigationController protocol
class ForwardingNavigationController: UINavigationController {
    override var childViewControllerForStatusBarStyle: UIViewController? {
        if let controller = viewControllers.last as? StatusBarOverriding as? UIViewController {
            return controller
        }
        else {
            return super.childViewControllerForStatusBarStyle
        }
    }
    
    override var childViewControllerForStatusBarHidden: UIViewController? {
        if let controller = viewControllers.last as? StatusBarOverriding as? UIViewController {
            return controller
        }
        else {
            return super.childViewControllerForStatusBarHidden
        }
        
    }
    
    override var shouldAutorotate: Bool {
        if let controller = viewControllers.last as? InterfaceOrientationOverriding as? UIViewController {
            return controller.shouldAutorotate
        }
        else {
            return super.shouldAutorotate
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if let controller = viewControllers.last as? InterfaceOrientationOverriding as? UIViewController {
            return controller.supportedInterfaceOrientations
        }
        else {
            return .portrait
        }
    }
    
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation {
        if let controller = viewControllers.last as? InterfaceOrientationOverriding as? UIViewController {
            return controller.preferredInterfaceOrientationForPresentation
        }
        else {
            return .portrait
        }
    }
}
