//
//  UIView+UIViewController.swift
//  edX
//
//  Created by Saeed Bashir on 7/15/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

extension UIView {
    func firstAvailableUIViewController() -> UIViewController? {
        return traverseResponderChainForUIViewController()
    }
    
    private func traverseResponderChainForUIViewController() -> UIViewController? {
        let nextResponder = self.next
        if let nextResponder = nextResponder {
            if nextResponder is UIViewController {
                return nextResponder as? UIViewController
            }
            else if nextResponder is UIView {
                let view = nextResponder as? UIView
                return view?.traverseResponderChainForUIViewController()
            }
        }
        
        return nil
    }
}
