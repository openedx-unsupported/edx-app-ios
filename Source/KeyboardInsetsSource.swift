//
//  KeyboardInsetsSource.swift
//  edX
//
//  Created by Akiva Leffert on 6/10/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

extension UIView.AnimationCurve {
    var asAnimationOptions : UIView.AnimationOptions {
        switch(self) {
        case .easeIn: return .curveEaseIn
        case .easeOut: return .curveEaseOut
        case .easeInOut: return .curveEaseInOut
        case .linear: return .curveLinear
        default: return .curveEaseIn
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
        
        NotificationCenter.default.oex_addObserver(observer: self, name: UIResponder.keyboardDidChangeFrameNotification.rawValue) { (notification, observer, _) -> Void in
            let globalFrame : CGRect = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue
            
            // Don't want to convert to the scroll view's coordinates since they're always moving so use the superview
            if let container = scrollView.superview {
                let localFrame = container.convert(globalFrame, from: nil)
                
                let intersection = localFrame.intersection(container.bounds);
                let keyboardHeight = intersection.size.height;
                observer.keyboardHeight = keyboardHeight
                
                let duration = (notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
                let curveValue = (notification.userInfo![UIResponder.keyboardAnimationCurveUserInfoKey] as! NSNumber).intValue
                let curve = UIView.AnimationCurve(rawValue: curveValue)
                let curveOptions = curve?.asAnimationOptions ?? UIView.AnimationOptions()
                UIView.animate(withDuration: duration, delay: 0, options: curveOptions, animations: {
                    observer.insetsDelegate?.contentInsetsSourceChanged(source: observer)
                }, completion: nil)
            }
        }
    }
    
    public var currentInsets : UIEdgeInsets {
        return UIEdgeInsets.init(top: 0, left: 0, bottom: keyboardHeight, right: 0)
    }
    
}
