//
//  UIViewController+Overlay.swift
//  edX
//
//  Created by Akiva Leffert on 12/23/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

private var StatusMessageHideActionKey = "StatusMessageHideActionKey"
private var SnackBarHideActionKey = "SnackBarHideActionKey"

private typealias StatusMessageRemovalInfo = (action : () -> Void, container : UIView)
private typealias TemporaryViewRemovalInfo = (action : () -> Void, container : UIView)

private class StatusMessageView : UIView {
    
    private let messageLabel = UILabel()
    private let margin = 20
    
    init(message: String) {
        super.init(frame: CGRectZero)

        messageLabel.numberOfLines = 0
        addSubview(messageLabel)
        
        self.backgroundColor = OEXStyles.sharedStyles().neutralDark().colorWithAlphaComponent(0.75)
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

private class VersionUpgradeView: UIView {
    private let messageLabel = UILabel()
    private let upgradeButton = UIButton(type: .System)
    private let dismissButton = UIButton(type: .System)
    private var messageLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralDark())
    }
    
    private var buttonLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .SemiBold, size: .Base, color: OEXStyles.sharedStyles().neutralDark())
    }
    
    init(message: String) {
        super.init(frame: CGRectZero)
        self.backgroundColor = OEXStyles.sharedStyles().warningBase()
        messageLabel.numberOfLines = 0
        messageLabel.attributedText = messageLabelStyle.attributedStringWithText(message)
        upgradeButton.setAttributedTitle(buttonLabelStyle.attributedStringWithText(Strings.VersionUpgrade.update), forState: .Normal)
        dismissButton.setAttributedTitle(buttonLabelStyle.attributedStringWithText(Strings.VersionUpgrade.dismiss), forState: .Normal)
        
        addSubview(messageLabel)
        addSubview(dismissButton)
        addSubview(upgradeButton)
        
        addConstrains()
        addButtonActions()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func addConstrains() {
        messageLabel.snp_makeConstraints { make in
            make.top.equalTo(self).offset(StandardVerticalMargin)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.trailing.equalTo(self).offset(-StandardHorizontalMargin)
        }
        
        upgradeButton.snp_makeConstraints { (make) in
            make.top.equalTo(messageLabel.snp_bottom)
            make.trailing.equalTo(self).offset(-StandardHorizontalMargin)
            make.bottom.equalTo(self).offset(-StandardVerticalMargin)
        }
        
        dismissButton.snp_makeConstraints { (make) in
            make.top.equalTo(messageLabel.snp_bottom)
            make.trailing.equalTo(upgradeButton.snp_leading).offset(-StandardHorizontalMargin)
            make.bottom.equalTo(self).offset(-StandardVerticalMargin)
        }
    }
    
    private func addButtonActions() {
        dismissButton.oex_addAction({[weak self] _ in
            self?.dismissView()
            }, forEvents: .TouchUpInside)
        
        upgradeButton.oex_addAction({ _ in
            if let appStoreURL = OEXConfig.sharedConfig().iOSAppStoreURL() {
                UIApplication.sharedApplication().openURL(appStoreURL)
            }}, forEvents: .TouchUpInside)
    }
    
    private func dismissView() {
        var container = superview
        if container == nil {
            container = self
        }
        
        UIView.animateWithDuration(animationDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.1, options: .CurveEaseOut, animations: {
            self.transform = CGAffineTransformIdentity
            }, completion: { _ in
                container!.removeFromSuperview()
        })
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
    
    func showSnackBarView(snackBarView : UIView) {
        let container = PassthroughView()
        container.clipsToBounds = true
        view.addSubview(container)
        container.addSubview(snackBarView)
        
        container.snp_makeConstraints {make in
            make.bottom.equalTo(bottomLayoutGuide)
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
        }
        snackBarView.snp_makeConstraints {make in
            make.edges.equalTo(container)
        }
        
        let hideAction = {[weak self] in
            let hideInfo = objc_getAssociatedObject(self, &SnackBarHideActionKey) as? Box<TemporaryViewRemovalInfo>
            if hideInfo?.value.container == container {
                objc_setAssociatedObject(self, &SnackBarHideActionKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            
            UIView.animateWithDuration(animationDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.1, options: .CurveEaseOut, animations: {
                snackBarView.transform = CGAffineTransformIdentity
                }, completion: { _ in
                    container.removeFromSuperview()
            })
        }
        
        // show
        UIView.animateWithDuration(0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.1, options: .CurveEaseIn, animations: { () -> Void in
            snackBarView.transform = CGAffineTransformIdentity
            }, completion: nil)
        
        let info : TemporaryViewRemovalInfo = (action: hideAction, container: container)
        objc_setAssociatedObject(self, &SnackBarHideActionKey, Box(info), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func showVersionUpgradeSnackBar(string: String) {
        let hideInfo = objc_getAssociatedObject(self, &SnackBarHideActionKey) as? Box<TemporaryViewRemovalInfo>
        hideInfo?.value.action()
        let view = VersionUpgradeView(message: string)
        showSnackBarView(view)
    }
    
    func hideSnackBar() {
        let hideInfo = objc_getAssociatedObject(self, &SnackBarHideActionKey) as? Box<TemporaryViewRemovalInfo>
        hideInfo?.value.action()
    }
}


// For use in testing only
extension UIViewController {
    
    var t_isShowingOverlayMessage : Bool {
        return objc_getAssociatedObject(self, &StatusMessageHideActionKey) as? Box<StatusMessageRemovalInfo> != nil
    }
    
    var t_isShowingSnackBar : Bool {
        return objc_getAssociatedObject(self, &SnackBarHideActionKey) as? Box<TemporaryViewRemovalInfo> != nil
    }
    
}
