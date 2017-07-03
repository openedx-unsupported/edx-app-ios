//
//  SwipeExpanding.swift
//
//  Created by Jeremy Koch
//  Copyright © 2017 Jeremy Koch. All rights reserved.
//

import UIKit

/**
 Adopt the `SwipeExpanding` protocol in objects that implement custom appearance of actions during expansion.
 */
public protocol SwipeExpanding {

    /**
     Asks your object for the animation timing parameters.
     
     - parameter buttons: The expansion action button, which includes expanding action plus the remaining actions in the view.
     
     - parameter expanding: The new expansion state.
     
     - parameter otherActionButtons: The other action buttons in the view, not including the action button being expanded.
     */

    func animationTimingParameters(buttons: [UIButton], expanding: Bool) -> SwipeExpansionAnimationTimingParameters
    
    /**
     Tells your object when the expansion state is changing.
     
     - parameter button: The expansion action button.
     
     - parameter expanding: The new expansion state.

     - parameter otherActionButtons: The other action buttons in the view, not including the action button being expanded.
     */
    func actionButton(_ button: UIButton, didChange expanding: Bool, otherActionButtons: [UIButton])
}

/**
 Specifies timing information for the overall expansion animation.
 */
public struct SwipeExpansionAnimationTimingParameters {
    
    /// Returns a `SwipeExpansionAnimationTimingParameters` instance with default animation parameters.
    public static var `default`: SwipeExpansionAnimationTimingParameters { return SwipeExpansionAnimationTimingParameters() }
    
    /// The duration of the expansion animation.
    public var duration: Double
    
    /// The delay before starting the expansion animation.
    public var delay: Double
    
    /**
     Contructs a new `SwipeExpansionAnimationTimingParameters` instance.
     
     - parameter duration: The duration of the animation.
     
     - parameter delay: The delay before starting the expansion animation.
     
     - returns: The new `SwipeExpansionAnimationTimingParameters` instance.
     */
    public init(duration: Double = 0.6, delay: Double = 0) {
        self.duration = duration
        self.delay = delay
    }
}
