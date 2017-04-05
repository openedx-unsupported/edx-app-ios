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
        super.init(frame: CGRect.zero)

        messageLabel.numberOfLines = 0
        addSubview(messageLabel)
        
        self.backgroundColor = OEXStyles.shared().neutralDark().withAlphaComponent(0.75)
        messageLabel.attributedText = statusMessageStyle.attributedString(withText: message)
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
    
    private var statusMessageStyle: OEXMutableTextStyle {
        let style = OEXMutableTextStyle(weight: .normal, size: .base, color: UIColor.white)
        style.alignment = .center;
        style.lineBreakMode = NSLineBreakMode.byWordWrapping;
        return style;
        
    }
}

private let visibleDuration: TimeInterval = 5.0
private let animationDuration: TimeInterval = 1.0

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
        
        let size = messageView.systemLayoutSizeFitting(CGSize(width: view.bounds.width, height: CGFloat.greatestFiniteMagnitude))
        messageView.transform = CGAffineTransform(translationX: 0, y: -size.height)
        container.layoutIfNeeded()
        
        let hideAction = {[weak self] in
            let hideInfo = objc_getAssociatedObject(self, &StatusMessageHideActionKey) as? Box<StatusMessageRemovalInfo>
            if hideInfo?.value.container == container {
                objc_setAssociatedObject(self, &StatusMessageHideActionKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            
            UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.1, options: .curveEaseOut, animations: {
                messageView.transform = CGAffineTransform(translationX: 0, y: -size.height)
                }, completion: { _ in
                    container.removeFromSuperview()
            })
        }
        
        // show
        UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.1, options: .curveEaseIn, animations: { () -> Void in
            messageView.transform = .identity
            }, completion: {_ in
                
                let delay = DispatchTime.now() + Double(Int64(visibleDuration * TimeInterval(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                DispatchQueue.main.asyncAfter(deadline: delay) {
                    hideAction()
                }
        })
        
        let info : StatusMessageRemovalInfo = (action: hideAction, container: container)
        objc_setAssociatedObject(self, &StatusMessageHideActionKey, Box(info), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func showOverlay(withMessage message : String) {
        let hideInfo = objc_getAssociatedObject(self, &StatusMessageHideActionKey) as? Box<StatusMessageRemovalInfo>
        hideInfo?.value.action()
        let view = StatusMessageView(message: message)
        showOverlayMessageView(messageView: view)
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
            
            UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.1, options: .curveEaseOut, animations: {
                snackBarView.transform = .identity
                }, completion: { _ in
                    container.removeFromSuperview()
            })
        }
        
        // show
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.1, options: .curveEaseIn, animations: { () -> Void in
            snackBarView.transform = .identity
            }, completion: nil)
        
        let info : TemporaryViewRemovalInfo = (action: hideAction, container: container)
        objc_setAssociatedObject(self, &SnackBarHideActionKey, Box(info), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }
    
    func showVersionUpgradeSnackBar(string: String) {
        let hideInfo = objc_getAssociatedObject(self, &SnackBarHideActionKey) as? Box<TemporaryViewRemovalInfo>
        hideInfo?.value.action()
        let view = VersionUpgradeView(message: string)
        showSnackBarView(snackBarView: view)
    }
    
    
    func showOfflineSnackBar(message: String, selector: Selector?) {
        let hideInfo = objc_getAssociatedObject(self, &SnackBarHideActionKey) as? Box<TemporaryViewRemovalInfo>
        hideInfo?.value.action()
        let view = OfflineView(message: message, selector: selector)
        showSnackBarView(snackBarView: view)
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
