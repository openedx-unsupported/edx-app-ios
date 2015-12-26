//
//  UIViewController+Overlay.swift
//  edX
//
//  Created by Akiva Leffert on 12/23/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

private var StatusMessageHideActionKey = "StatusMessageHideActionKey"

private typealias StatusMessageRemovalInfo = (action : () -> Void, container : UIView)

private class StatusMessageView : UIView {
    
    private let messageLabel = UILabel()
    private let margin = 20
    
    init(message: String) {
        super.init(frame: CGRectZero)
        
        addSubview(messageLabel)
        
        self.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.75)
        messageLabel.attributedText = OEXStatusMessageViewController.statusMessageStyle().attributedStringWithText(message)
        messageLabel.snp_makeConstraints { make in
            make.top.equalTo(self).offset(margin)
            make.leading.equalTo(self).offset(margin)
            make.trailing.equalTo(self).offset(-margin)
            make.bottom.equalTo(self).offset(-margin)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private let visibleDuration: NSTimeInterval = 5.0
private let animationDuration: NSTimeInterval = 1.0

extension UIViewController {
    
    func showOverlayMessageView(messageView : UIView) {
        let container = PassthroughView()
        container.clipsToBounds = true
        view.addSubview(container)
        container.addSubview(messageView)
        
        container.snp_makeConstraints {make in
            make.top.equalTo(topLayoutGuide)
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
        }
        messageView.snp_makeConstraints {make in
            make.edges.equalTo(container)
        }
        
        let size = messageView.systemLayoutSizeFittingSize(CGSizeMake(view.bounds.width, CGFloat.max))
        messageView.transform = CGAffineTransformMakeTranslation(0, -size.height)
        container.layoutIfNeeded()
        
        let hideAction = {[weak self] in
            let hideInfo = objc_getAssociatedObject(self, &StatusMessageHideActionKey) as? Box<StatusMessageRemovalInfo>
            if hideInfo?.value.container == container {
                objc_setAssociatedObject(self, &StatusMessageHideActionKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            
            UIView.animateWithDuration(animationDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.1, options: .CurveEaseOut, animations: {
                messageView.transform = CGAffineTransformMakeTranslation(0, -size.height)
                }, completion: { _ in
                    container.removeFromSuperview()
            })
        }
        
        // show
        UIView.animateWithDuration(animationDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.1, options: .CurveEaseIn, animations: { () -> Void in
            messageView.transform = CGAffineTransformIdentity
            }, completion: {_ in
                let delay = dispatch_time(DISPATCH_TIME_NOW, Int64(visibleDuration * NSTimeInterval(NSEC_PER_SEC)))
                dispatch_after(delay, dispatch_get_main_queue()) {
                    hideAction()
                }
        })
        
        let info : StatusMessageRemovalInfo = (action: hideAction, container: container)
        objc_setAssociatedObject(self, &StatusMessageHideActionKey, Box(info), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func showOverlayMessage(string : String) {
        let hideInfo = objc_getAssociatedObject(self, &StatusMessageHideActionKey) as? Box<StatusMessageRemovalInfo>
        hideInfo?.value.action()
        let view = StatusMessageView(message: string)
        showOverlayMessageView(view)
    }
}


// For use in testing only
extension UIViewController {
    
    var t_isShowingOverlayMessage : Bool {
        return objc_getAssociatedObject(self, &StatusMessageHideActionKey) as? Box<StatusMessageRemovalInfo> != nil
    }
    
}
