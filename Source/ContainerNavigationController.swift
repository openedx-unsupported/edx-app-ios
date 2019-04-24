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
class ForwardingNavigationController: UINavigationController, StatusBarOverriding {
    
    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        view.handleDynamicTypeNotification()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var childForStatusBarStyle: UIViewController? {
        if let controller = viewControllers.last as? StatusBarOverriding as? UIViewController {
            return controller
        }
        else {
            return super.childForStatusBarStyle
        }
    }
    
    override var childForStatusBarHidden: UIViewController? {
        if let controller = viewControllers.last as? StatusBarOverriding as? UIViewController {
            return controller
        }
        else {
            return super.childForStatusBarHidden
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
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle(barStyle: .default)
    }
}

extension UINavigationController {
    
    struct AssociatedKeys {
        static var completionHandler = "completionHandletObject"
    }
    typealias Completion = ()->Void
    
    var completionHandler:Completion {
        get {
            guard let value = objc_getAssociatedObject(self, &AssociatedKeys.completionHandler) as? Completion else { return {} }
            return value
        }
        set(newValue) {
            objc_setAssociatedObject(self, &AssociatedKeys.completionHandler, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func pushViewController(viewController: UIViewController, completion :@escaping Completion) {
        completionHandler = completion
        pushViewController(viewController, animated: true)
    }
}
