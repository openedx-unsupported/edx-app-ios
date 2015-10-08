//
//  RevealViewController.swift
//  edX
//
//  Created by Akiva Leffert on 9/30/15.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit


class RevealViewController: SWRevealViewController, SWRevealViewControllerDelegate {
    
    private var overlayButton : UIButton!
    
    func loadStoryboardControllers() {
        // Do nothing. Just want to remove parent behavior
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        overlayButton = UIButton()
        overlayButton.hidden = true
        overlayButton.alpha = 0
        overlayButton.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        overlayButton.backgroundColor = OEXStyles.sharedStyles().neutralBlack()
        overlayButton.exclusiveTouch = true
        overlayButton.oex_addAction({[weak self] _ in
            self?.revealToggleAnimated(true)
            }, forEvents: .TouchUpInside)
    }
    
    private func postNavigationStateChanged(state : OEXSideNavigationState) {
        NSNotificationCenter.defaultCenter().postNotificationName(OEXSideNavigationChangedStateNotification, object: self, userInfo : [
            OEXSideNavigationChangedStateKey: state.rawValue as NSNumber
            ])
    }
    
    func revealController(revealController: SWRevealViewController!, didMoveToPosition position: FrontViewPosition) {
        
        switch position {
        case .Left:
            // Hide
            postNavigationStateChanged(.Hidden)
            UIView.animateWithDuration(0.2, animations:
                { _ in
                    self.overlayButton?.alpha = 0
                }, completion: {_ in
                    self.overlayButton?.hidden = true
                    self.overlayButton?.removeFromSuperview()
                }
            )
        case .Right:
            // Show
            postNavigationStateChanged(.Visible)
            overlayButton.frame = frontViewController.view.bounds
            frontViewController.view.addSubview(overlayButton)
            overlayButton.hidden = false
            UIView.animateWithDuration(0.5) { _ in
                self.overlayButton.alpha = 0.5
            }
        default:
            // Do nothing
            break
        }
        
    }
    

}
