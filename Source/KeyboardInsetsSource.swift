//
//  KeyboardInsetsSource.swift
//  edX
//
//  Created by Akiva Leffert on 6/10/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

extension UIViewAnimationCurve {
    var asAnimationOptions : UIViewAnimationOptions {
        switch(self) {
        case .easeIn: return UIViewAnimationOptions.curveEaseIn
        case .easeOut: return UIViewAnimationOptions.curveEaseOut
        case .easeInOut: return UIViewAnimationOptions.curveEaseInOut
        case .linear: return UIViewAnimationOptions.curveLinear
        }
    }
}

public class KeyboardInsetsSource : NSObject, ContentInsetsSource {
    public weak var insetsDelegate : ContentInsetsSourceDelegate?
    public let affectsScrollIndicators = true
    
    private let scrollView : UIScrollView
    
    private var keyboardHeight : CGFloat = 0
    
    public init(scrollView : UIScrollView) {
        self.scrollView = scrollView
        
        super.init()
        
        NotificationCenter.default.oex_addObserver(observer: self, name: NSNotification.Name.UIKeyboardDidChangeFrame.rawValue) { (notification, observer, _) -> Void in
            let globalFrame : CGRect = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            
            // Don't want to convert to the scroll view's coordinates since they're always moving so use the superview
            if let container = scrollView.superview {
                let localFrame = container.convert(globalFrame, from: nil)
                
                let intersection = localFrame.intersection(container.bounds);
                let keyboardHeight = intersection.size.height;
                observer.keyboardHeight = keyboardHeight
                
                let duration = (notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
                let curveValue = (notification.userInfo![UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).intValue
                let curve = UIViewAnimationCurve(rawValue: curveValue)
                let curveOptions = curve?.asAnimationOptions ?? UIViewAnimationOptions()
                UIView.animate(withDuration: duration, delay: 0, options: curveOptions, animations: {
                    observer.insetsDelegate?.contentInsetsSourceChanged(source: observer)
                }, completion: nil)
            }
        }
    }
    
    public var currentInsets : UIEdgeInsets {
        return UIEdgeInsetsMake(0, 0, keyboardHeight, 0)
    }
    
}
