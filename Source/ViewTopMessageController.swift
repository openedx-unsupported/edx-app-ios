//
//  ViewTopMessageController.swift
//  edX
//
//  Created by Akiva Leffert on 6/4/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

public class ViewTopMessageController : NSObject, ContentInsetsSource {

    weak public var insetsDelegate : ContentInsetsSourceDelegate?
    
    private let containerView = UIView(frame: CGRect.zero)
    fileprivate let messageView : UIView
    
    private var wasActive : Bool = false
    
    private let active : (Void) -> Bool
    
    public init(messageView: UIView, active : @escaping (Void) -> Bool) {
        self.active = active
        self.messageView = messageView
        
        super.init()
        containerView.addSubview(messageView)
        containerView.setNeedsUpdateConstraints()
        containerView.clipsToBounds = true
        
        update()
    }
    
    public var affectsScrollIndicators : Bool {
        return true
    }
    
    final public var currentInsets : UIEdgeInsets {
        let height = active() ? messageView.bounds.size.height : 0
        return UIEdgeInsets(top: height, left: 0, bottom: 0, right: 0)
    }
    
    final public func setupInController(controller : UIViewController) {
        controller.view.addSubview(containerView)
        containerView.snp_makeConstraints {make in
            make.leading.equalTo(controller.view)
            make.trailing.equalTo(controller.view)
            make.top.equalTo(controller.snp_topLayoutGuideBottom)
            make.height.equalTo(messageView)
        }
    }
    
    final private func update() {
        messageView.snp_remakeConstraints { make in
            make.leading.equalTo(containerView)
            make.trailing.equalTo(containerView)
            
            if active() {
                containerView.isUserInteractionEnabled = true
                make.top.equalTo(containerView.snp_top)
            }
            else {
                containerView.isUserInteractionEnabled = false
                make.bottom.equalTo(containerView.snp_top)
            }
        }
        messageView.setNeedsLayout()
        messageView.layoutIfNeeded()
        
        if(!wasActive && active()) {
            containerView.superview?.bringSubview(toFront: containerView)
        }
        wasActive = active()
        
        self.insetsDelegate?.contentInsetsSourceChanged(source: self)
    }
    
    
    final func updateAnimated() {
        UIView.animate(withDuration: 0.4, delay: 0.0,
            usingSpringWithDamping: 1, initialSpringVelocity: 0.1,
            options: UIViewAnimationOptions(),
            animations: {
                self.update()
            }, completion:nil)
        
    }
}


extension ViewTopMessageController {
    public var t_messageHidden : Bool {
        return messageView.frame.maxY <= 0
    }
}
