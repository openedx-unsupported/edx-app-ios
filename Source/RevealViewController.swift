//
//  RevealViewController.swift
//  edX
//
//  Created by Akiva Leffert on 9/30/15.
//  Copyright © 2015 edX. All rights reserved.
//

import UIKit


class RevealViewController: SWRevealViewController, SWRevealViewControllerDelegate {

    // Dims the front content when the side drawer is visible
    private var dimmingOverlay : UIButton!
    
    override init!(rearViewController: UIViewController!, frontViewController: UIViewController!) {
        super.init(rearViewController: rearViewController, frontViewController: frontViewController)
        self.rearViewRevealWidth = 300
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.rearViewRevealWidth = 300
    }
    
    func loadStoryboardControllers() {
        // Do nothing. Just want to remove parent behavior
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dimmingOverlay = UIButton()
        dimmingOverlay.hidden = true
        dimmingOverlay.alpha = 0
        dimmingOverlay.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        dimmingOverlay.backgroundColor = OEXStyles.sharedStyles().neutralBlack()
        dimmingOverlay.exclusiveTouch = true
        dimmingOverlay.oex_addAction({[weak self] _ in
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
                    self.dimmingOverlay?.alpha = 0
                }, completion: {_ in
                    self.dimmingOverlay?.hidden = true
                    self.dimmingOverlay?.removeFromSuperview()
                }
            )
        case .Right:
            // Show
            postNavigationStateChanged(.Visible)
            dimmingOverlay.frame = frontViewController.view.bounds
            frontViewController.view.addSubview(dimmingOverlay)
            dimmingOverlay.hidden = false
            UIView.animateWithDuration(0.5) { _ in
                self.dimmingOverlay.alpha = 0.5
            }
        default:
            // Do nothing
            break
        }
        
    }
    

}
