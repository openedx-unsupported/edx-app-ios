//
//  OfflineModeController.swift
//  edX
//
//  Created by Akiva Leffert on 5/15/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit


/// Convenient class for supporting an offline mode overlay above the top of a controller or its navigation bar
/// as appropriate
///
/// If you need to use this in the context of a scroll view, it's recommended to use `ContentInsetsController` instead
public class OfflineModeController: NSObject, ContentInsetsSource {
    
    weak var insetsDelegate : ContentInsetsSourceDelegate?
    
    private let containerView = UIView(frame: CGRectZero)
    private let offlineMessage : OfflineModeView
    private let reachability : Reachability
    
    var currentInsets : UIEdgeInsets {
        let height = reachability.isReachable() ? 0 : offlineMessage.bounds.size.height
        return UIEdgeInsets(top: height, left: 0, bottom: 0, right: 0)
    }
    
    public init(reachability : Reachability = InternetReachability(), styles : OEXStyles) {
        offlineMessage = OfflineModeView(frame : CGRectZero, styles : styles)
        
        self.reachability = reachability
        reachability.startNotifier()
        
        super.init()
        
        NSNotificationCenter.defaultCenter().oex_addObserver(self, name: kReachabilityChangedNotification) { (notification, observer, _) in
            
            UIView.animateWithDuration(0.4, delay: 0.0,
                usingSpringWithDamping: 1, initialSpringVelocity: 0.1,
                options: UIViewAnimationOptions(),
                animations: {
                    observer.reachabilityChanged(reachability)
                }, completion:nil)
        }
        
        containerView.addSubview(offlineMessage)
        
        reachabilityChanged(reachability)
        containerView.setNeedsUpdateConstraints()
    }
    
    public func setupInController(controller : UIViewController) {
        controller.view.addSubview(containerView)
        containerView.snp_makeConstraints {make in
            make.leading.equalTo(controller.view)
            make.trailing.equalTo(controller.view)
            make.top.equalTo(controller.topLayoutGuide)
            make.height.equalTo(offlineMessage)
        }
    }
    
    private func reachabilityChanged(reachability: Reachability) {
        offlineMessage.snp_remakeConstraints { make in
            make.leading.equalTo(containerView)
            make.trailing.equalTo(containerView)
            
            if reachability.isReachable() {
                make.bottom.equalTo(containerView.snp_top).constraint
            }
            else {
                make.top.equalTo(containerView.snp_top).constraint
            }
        }
        offlineMessage.setNeedsLayout()
        offlineMessage.layoutIfNeeded()
        
        containerView.superview?.bringSubviewToFront(containerView)
        
        self.insetsDelegate?.contentInsetsSourceChanged(self)
    }
}

extension OfflineModeController {
    public var t_messageHidden : Bool {
        return CGRectGetMaxY(offlineMessage.frame) <= 0
    }
}
