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
    
    func isiPad() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    func currentOrientation() -> UIInterfaceOrientation {
        return UIApplication.shared.statusBarOrientation
    }
    
   @objc func isModal() -> Bool {
        return (navigationController?.viewControllers.firstIndex(of: self) == 0) &&
            (presentingViewController?.presentedViewController == self
            || isRootModal()
            || tabBarController?.presentingViewController is UITabBarController)
            || self is UIActivityViewController
            || self is UIAlertController
    }
    
    @objc func isRootModal() -> Bool {
        return (navigationController != nil && navigationController?.presentingViewController?.presentedViewController == navigationController)
    }
    
    func configurePresentationController(withSourceView sourceView: UIView) {
        if UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad {
            popoverPresentationController?.sourceView = sourceView
            popoverPresentationController?.sourceRect = sourceView.bounds
        }
    }
    
    @objc func addBackBarButton() {
        let backItem = UIBarButtonItem(image: Icon.ArrowLeft.imageWithFontSize(size: 40), style: .plain, target: nil, action: nil)
        backItem.oex_setAction { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        navigationItem.leftBarButtonItem = backItem
    }
}
