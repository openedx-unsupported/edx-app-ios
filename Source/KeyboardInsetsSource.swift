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
        case .EaseIn: return UIViewAnimationOptions.CurveEaseIn
        case .EaseOut: return UIViewAnimationOptions.CurveEaseOut
        case .EaseInOut: return UIViewAnimationOptions.CurveEaseInOut
        case .Linear: return UIViewAnimationOptions.CurveLinear
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
        
        NSNotificationCenter.defaultCenter().oex_addObserver(self, name: UIKeyboardDidChangeFrameNotification) { (notification, observer, _) -> Void in
            let globalFrame : CGRect = (notification.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
            
            // Don't want to convert to the scroll view's coordinates since they're always moving so use the superview
            if let container = scrollView.superview {
                let localFrame = container.convertRect(globalFrame, fromView: container)
                
                let intersection = CGRectIntersection(localFrame, container.bounds);
                let keyboardHeight = intersection.size.height;
                observer.keyboardHeight = keyboardHeight
                
                let duration = (notification.userInfo![UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
                let curveValue = (notification.userInfo![UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).integerValue
                let curve = UIViewAnimationCurve(rawValue: curveValue)
                let curveOptions = curve?.asAnimationOptions ?? UIViewAnimationOptions()
                UIView.animateWithDuration(duration, delay: 0, options: curveOptions, animations: {
                    observer.insetsDelegate?.contentInsetsSourceChanged(observer)
                }, completion: nil)
            }
        }
    }
    
    public var currentInsets : UIEdgeInsets {
        return UIEdgeInsetsMake(0, 0, keyboardHeight, 0)
    }
    
}