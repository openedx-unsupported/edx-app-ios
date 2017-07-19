//
//  SwipeAnimator.swift
//  edX
//
//  Created by Salman on 04/07/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation

protocol SwipeAnimator {
    //A Boolean value indicating whether the animation is currently running.
    var isRunning: Bool { get }
    
     //The animation to be run by the SwipeAnimator.
    func addAnimations(_ animation: @escaping () -> Void)
    
    //Completion handler for the animation that is going to be started.
    func addCompletion(completion: @escaping (Bool) -> Void)
    
    //Starts the defined animation
    func startAnimation()

    //Stops the animations at their current positions
    func stopAnimation(_ withoutFinishing: Bool)
}

class UIViewSpringAnimator: SwipeAnimator {
    var isRunning: Bool = false
    
    let duration:TimeInterval
    let damping:CGFloat
    let velocity:CGFloat
    
    var animations:(() -> Void)?
    var completion:((Bool) -> Void)?
    
    required init(duration: TimeInterval,
                  damping: CGFloat,
                  initialVelocity velocity: CGFloat = 0) {
        self.duration = duration
        self.damping = damping
        self.velocity = velocity
    }
    
    func addAnimations(_ animations: @escaping () -> Void) {
        self.animations = animations
    }
    
    func addCompletion(completion: @escaping (Bool) -> Void) {
        self.completion = { [weak self] finished in
            guard self?.isRunning == true else { return }
            
            self?.isRunning = false
            self?.animations = nil
            self?.completion = nil
            
            completion(finished)
        }
    }
    
    func startAnimation() {
        guard let animations = animations else { return }
        
        isRunning = true
        
        UIView.animate(withDuration: duration,
                       delay: 0,
                       usingSpringWithDamping: damping,
                       initialSpringVelocity: velocity,
                       options: [.curveEaseInOut, .allowUserInteraction],
                       animations: animations,
                       completion: completion)
    }
    
    func stopAnimation(_ withoutFinishing: Bool) {
        isRunning = false
    }
}
