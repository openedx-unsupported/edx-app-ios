//
//  SnackbarViews.swift
//  edX
//
//  Created by Saeed Bashir on 7/15/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
private let animationDuration: NSTimeInterval = 1.0

public class VersionUpgradeView: UIView {
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
        
        addConstraints()
        addButtonActions()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addConstraints() {
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
        
        upgradeButton.oex_addAction({[weak self]  _ in
            if let URL = OEXConfig.sharedConfig().appUpgradeConfig.iOSAppStoreURL() {
                if UIApplication.sharedApplication().canOpenURL(URL) {
                    self?.dismissView()
                    UIApplication.sharedApplication().openURL(URL)
                }
            }
            }, forEvents: .TouchUpInside)
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

public class OfflineView: UIView {
    private let messageLabel = UILabel()
    private let reloadButton = UIButton(type: .System)
    private let dismissButton = UIButton(type: .System)
    private var selector: Selector?
    private var messageLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralDark())
    }
    
    private var buttonLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .SemiBold, size: .Base, color: OEXStyles.sharedStyles().neutralDark())
    }
    
    init(message: String, selector: Selector?) {
        super.init(frame: CGRectZero)
        self.selector = selector
        self.backgroundColor = OEXStyles.sharedStyles().warningBase()
        messageLabel.numberOfLines = 0
        messageLabel.attributedText = messageLabelStyle.attributedStringWithText(message)
        reloadButton.setAttributedTitle(buttonLabelStyle.attributedStringWithText(Strings.reload), forState: .Normal)
        dismissButton.setAttributedTitle(buttonLabelStyle.attributedStringWithText(Strings.VersionUpgrade.dismiss), forState: .Normal)
        addSubview(messageLabel)
        addSubview(dismissButton)
        addSubview(reloadButton)
        
        addConstraints()
        addButtonActions()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func addConstraints() {
        messageLabel.snp_makeConstraints { make in
            make.top.equalTo(self).offset(StandardVerticalMargin)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.trailing.lessThanOrEqualTo(dismissButton).offset(-StandardHorizontalMargin)
            make.centerY.equalTo(reloadButton)
        }
        
        reloadButton.snp_makeConstraints { (make) in
            make.top.equalTo(messageLabel)
            make.trailing.equalTo(self).offset(-StandardHorizontalMargin)
            make.bottom.equalTo(self).offset(-StandardVerticalMargin)
        }
        
        dismissButton.snp_makeConstraints { (make) in
            make.top.equalTo(reloadButton)
            make.trailing.equalTo(reloadButton.snp_leading).offset(-StandardHorizontalMargin)
            make.bottom.equalTo(self).offset(-StandardVerticalMargin)
        }
    }
    
    private func addButtonActions() {
        dismissButton.oex_addAction({[weak self] _ in
            self?.dismissView()
            }, forEvents: .TouchUpInside)
        
        reloadButton.oex_addAction({[weak self] _ in
            let controller = self?.firstAvailableUIViewController()
            if let controller = controller, selector = self?.selector {
                if controller.respondsToSelector(selector) && OEXRouter.sharedRouter().environment.reachability.isReachable() {
                    controller.performSelector(selector)
                    self?.dismissView()
                }
            }
            else {
                self?.dismissView()
            }
            }, forEvents: .TouchUpInside)
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