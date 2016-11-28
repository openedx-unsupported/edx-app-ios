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
        self.rightViewRevealWidth = self.rearViewRevealWidth
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.rearViewRevealWidth = 300
        self.rightViewRevealWidth = self.rearViewRevealWidth
    }
    
    func loadStoryboardControllers() {
        // Do nothing. Just want to remove parent behavior
    }
    
    override func loadView() {
        dimmingOverlay = UIButton()
        dimmingOverlay.hidden = true
        dimmingOverlay.alpha = 0
        dimmingOverlay.autoresizingMask = [.FlexibleHeight, .FlexibleWidth]
        dimmingOverlay.backgroundColor = OEXStyles.sharedStyles().neutralBlack()
        dimmingOverlay.exclusiveTouch = true
        dimmingOverlay.accessibilityLabel = Strings.accessibilityCloseMenu
        dimmingOverlay.oex_addAction({[weak self] _ in
            self?.toggleDrawerAnimated(true)
            }, forEvents: .TouchUpInside)
        
        super.loadView()
    }
    
    private func postNavigationStateChanged(state : OEXSideNavigationState) {
        NSNotificationCenter.defaultCenter().postNotificationName(OEXSideNavigationChangedStateNotification, object: self, userInfo : [
            OEXSideNavigationChangedStateKey: state.rawValue as NSNumber
            ])
    }
    
    private func sideNavigationStateForPosition(position : FrontViewPosition) -> OEXSideNavigationState? {
        if isRightToLeft {
            switch position {
            case .Left:
                return .Hidden
            case .LeftSide:
                return .Visible
            default: return nil
            }
        }
        else {
            switch position {
            case .Left:
                return .Hidden
            case .Right:
                return .Visible
            default: return nil
            }
        }
    }
    
    private func defaultVOFocus() {
        view.accessibilityElements = view.subviews
    }
    
    @objc private func defaultMenuVOFocus() {
        view.accessibilityElements = [dimmingOverlay, rearViewController.view.subviews]
        UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification,  dimmingOverlay)
    }
    
    func revealController(revealController: SWRevealViewController!, didMoveToPosition position: FrontViewPosition) {
        guard let state = self.sideNavigationStateForPosition(position) else {
            return
        }
        
        switch state {
        case .Hidden:
            UIView.animateWithDuration(0.2, animations:
                { _ in
                    self.dimmingOverlay.alpha = 0
                }, completion: {_ in
                    self.dimmingOverlay.hidden = true
                    self.dimmingOverlay.removeFromSuperview()
                    self.defaultVOFocus()
                }
            )
        case .Visible:
            dimmingOverlay.frame = frontViewController.view.bounds
            frontViewController.view.addSubview(dimmingOverlay)
            dimmingOverlay.hidden = false
            UIView.animateWithDuration(0.5) { _ in
                self.dimmingOverlay.alpha = 0.5
            }
            defaultMenuVOFocus()
        }
        postNavigationStateChanged(state)
    }

    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if let container = self.frontViewController as? UINavigationController,
            topController = container.topViewController where topController is InterfaceOrientationOverriding
        {
            return topController.supportedInterfaceOrientations()
        }
        return .Portrait
    }

}

extension SWRevealViewController {
    
    func setDrawerViewController(controller : UIViewController, animated : Bool) {
        if isRightToLeft {
            setRightViewController(controller, animated: animated)
        }
        else {
            setRearViewController(controller, animated: animated)
        }
    }
    
    func toggleDrawerAnimated(animated: Bool) {
        if isRightToLeft {
            self.rightRevealToggleAnimated(animated)
        }
        else {
            self.revealToggleAnimated(animated)
        }
    }
    
    // Note that this is different from the global right to left setting.
    // Prior to iOS 9, the overall navigation was not flipped even though individual screens might be
    private var isRightToLeft : Bool {
        if #available(iOS 9.0, *) {
            if UIApplication.sharedApplication().userInterfaceLayoutDirection == .RightToLeft {
                return true
            }
        }
        return false
    }
    
    @objc var drawerViewController : UIViewController {
        if isRightToLeft {
            return self.rightViewController
        }
        else {
            return self.rearViewController
        }
    }
    
}
