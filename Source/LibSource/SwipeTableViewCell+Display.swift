//
//  SwipeTableViewCell+Display.swift
//
//  Created by Jeremy Koch
//  Copyright © 2017 Jeremy Koch. All rights reserved.
//

import UIKit

extension SwipeTableViewCell {
    
    /**
     Hides the swipe actions and returns the cell to center.
     
     - parameter animated: Specify `true` to animate the hiding of the swipe actions or `false` to hide it immediately.
     
     - parameter completion: The closure to be executed once the animation has finished. A `Boolean` argument indicates whether or not the animations actually finished before the completion handler was called.     
     */
    public func hideSwipe(animated: Bool, completion: ((Bool) -> Void)? = nil) {
        guard state == .left || state == .right else { return }
        
        state = .animatingToCenter
        
        tableView?.setGestureEnabled(true)
        
        let targetCenter = self.targetCenter(active: false)
        
        if animated {
            animate(toOffset: targetCenter) { complete in
                self.reset()
                completion?(complete)
            }
        } else {
            center = CGPoint(x: targetCenter, y: self.center.y)
            reset()
        }
    }

}
