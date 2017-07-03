//
//  SwipeActionTransitioning.swift
//
//  Created by Jeremy Koch
//  Copyright © 2017 Jeremy Koch. All rights reserved.
//

import UIKit

/**
 Adopt the `SwipeActionTransitioning` protocol in objects that implement custom appearance of actions during transition.
 */
public protocol SwipeActionTransitioning {
    /**
     Tells the delegate that transition change has occured.
     */
    func didTransition(with context: SwipeActionTransitioningContext) -> Void
}

/**
 The `SwipeActionTransitioningContext` type provides information relevant to a specific action as transitioning occurs.
 */
public struct SwipeActionTransitioningContext {
    /// The unique action identifier.
    public let actionIdentifier: String?
    
    /// The button that is changing.
    public let button: UIButton
    
    /// The old visibility percentage between 0.0 and 1.0.
    public let newPercentVisible: CGFloat
    
    /// The new visibility percentage between 0.0 and 1.0.
    public let oldPercentVisible: CGFloat
    
    internal let wrapperView: UIView
    
    internal init(actionIdentifier: String?, button: UIButton, newPercentVisible: CGFloat, oldPercentVisible: CGFloat, wrapperView: UIView) {
        self.actionIdentifier = actionIdentifier
        self.button = button
        self.newPercentVisible = newPercentVisible
        self.oldPercentVisible = oldPercentVisible
        self.wrapperView = wrapperView
    }
    
    /// Sets the background color behind the action button.
    /// 
    /// - parameter color: The background color.
    public func setBackgroundColor(_ color: UIColor?) {
        wrapperView.backgroundColor = color
    }
}
