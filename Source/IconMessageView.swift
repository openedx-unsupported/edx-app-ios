//
//  IconMessageView.swift
//  edX
//
//  Created by Akiva Leffert on 5/12/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import UIKit

private let IconMessageSize : CGFloat = 80.0
private let IconMessageRotatedSize : CGFloat = IconMessageSize * 1.75
private let IconMessageTextWidth : CGFloat = 240.0
private let IconMessageMargin : CGFloat = 15.0
private let MessageButtonMargin : CGFloat = 15.0
private let BottomButtonHorizontalMargin : CGFloat = 12.0
private let BottomButtonVerticalMargin : CGFloat = 6.0


public struct MessageButtonInfo {
    let title : String
    let action : () -> Void
}

class IconMessageView : UIView {
    private var hasBottomButton = false
    
    private var buttonFontStyle : OEXTextStyle {
        return OEXTextStyle(weight :.Normal, size : .Base, color : OEXStyles.sharedStyles().neutralDark())
    }
    
    private let iconView : UIImageView
    private let messageView : UILabel
    private var bottomButton : UIButton
    
    private let container : UIView
    
    init(icon : Icon? = nil, message : String? = nil) {
        
        container = UIView(frame: CGRectZero)
        iconView = UIImageView(frame: CGRectZero)
        messageView = UILabel(frame : CGRectZero)
        bottomButton = UIButton(type: .System)
        super.init(frame: CGRectZero)
        
        self.translatesAutoresizingMaskIntoConstraints = false
        
        setupViews(icon : icon, message : message)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var message : String? {
        get {
            return messageView.text
        }
        set {
            messageView.attributedText = newValue.map { messageStyle.attributedStringWithText($0) }
        }
    }
    
    var attributedMessage : NSAttributedString? {
        get {
            return messageView.attributedText
        }
        set {
            messageView.attributedText = newValue
        }
    }
    
    var accessibilityMessage : String? {
        get {
            return messageView.accessibilityLabel
        }
        set {
            messageView.accessibilityLabel = newValue
        }
    }
    
    var icon : Icon? {
        didSet {
            iconView.image = icon?.imageWithFontSize(IconMessageSize)
        }
    }
    
    private var buttonTitle : String? {
        get {
            return bottomButton.titleLabel?.text
        }
        set {
            if let title = newValue {
                let attributedTitle = buttonFontStyle.withWeight(.SemiBold).attributedStringWithText(title)
                bottomButton.setAttributedTitle(attributedTitle, forState: .Normal)
                addButtonBorder()
            }
            else {
                bottomButton.setAttributedTitle(nil, forState: .Normal)
            }
            
        }
    }
    
    var messageStyle : OEXTextStyle  {
        let style = OEXMutableTextStyle(weight: .SemiBold, size: .Base, color : OEXStyles.sharedStyles().neutralDark())
        style.alignment = .Center
        
        return style
    }
    
    private func setupViews(icon icon : Icon?, message : String?) {
        self.icon = icon
        self.message = message
        
        iconView.tintColor = OEXStyles.sharedStyles().neutralLight()
        
        messageView.numberOfLines = 0
        
        bottomButton.contentEdgeInsets = UIEdgeInsets(top: BottomButtonVerticalMargin, left: BottomButtonHorizontalMargin, bottom: BottomButtonVerticalMargin, right: BottomButtonHorizontalMargin)
        
        addSubview(container)
        container.addSubview(iconView)
        container.addSubview(messageView)
        container.addSubview(bottomButton)

    }
    
    override func updateConstraints() {
        container.snp_makeConstraints { (make) -> Void in
            make.center.equalTo(self)
            make.leading.greaterThanOrEqualTo(self)
            make.trailing.lessThanOrEqualTo(self)
            make.top.greaterThanOrEqualTo(self)
            make.bottom.lessThanOrEqualTo(self)
        }
        
        iconView.snp_updateConstraints { (make) -> Void in
            make.leading.equalTo(container)
            make.trailing.equalTo(container)
            make.top.equalTo(container)
        }
        
        messageView.snp_remakeConstraints { (make) -> Void in
            make.top.equalTo(self.iconView.snp_bottom).offset(IconMessageMargin)
            make.centerX.equalTo(container)
            make.width.equalTo(IconMessageTextWidth)
            if !hasBottomButton {
                make.bottom.equalTo(container)
            }
        }
        
        if hasBottomButton {
            bottomButton.snp_remakeConstraints { (make) -> Void in
                make.top.equalTo(self.messageView.snp_bottom).offset(MessageButtonMargin)
                make.centerX.equalTo(container)
                make.bottom.equalTo(container)
            }
        }
        super.updateConstraints()
    }
    
    func setupForOutdatedVersionError() {
        message = Strings.VersionUpgrade.outDatedMessage
        icon = .Warning
        
        buttonInfo = MessageButtonInfo(title : Strings.VersionUpgrade.update)
        {
            if let URL = OEXConfig.sharedConfig().appUpgradeConfig.iOSAppStoreURL() {
                UIApplication.sharedApplication().openURL(URL)
            }
        }
    }
    
    func showError(message: NSAttributedString?, icon: Icon?) {
        attributedMessage = message
        self.icon = icon ?? .UnknownError
        
        if let controller = self.container.firstAvailableUIViewController() as? LoadStateViewController where controller.isSupportingReload() {
            buttonInfo = MessageButtonInfo(title : Strings.reload)
            {
                controller.loadStateViewReload()
            }
        }
    }
    
    func showError(message: String?, icon: Icon?) {
        let attributedMessage = messageStyle.attributedStringWithText(message)
        showError(attributedMessage, icon: icon)
    }
    
    var buttonInfo : MessageButtonInfo? {
        didSet {
            bottomButton.oex_removeAllActions()
            buttonTitle = buttonInfo?.title
            if let action = buttonInfo?.action {
                bottomButton.oex_addAction({button in action() }, forEvents: .TouchUpInside)
            }
        }
    }
    
    func addButtonBorder() {
        hasBottomButton = true
        setNeedsUpdateConstraints()
        let bottomButtonLayer = bottomButton.layer
        bottomButtonLayer.cornerRadius = 4.0
        bottomButtonLayer.borderWidth = 1.0
        bottomButtonLayer.borderColor = OEXStyles.sharedStyles().neutralLight().CGColor
    }
    
    func rotateImageViewClockwise(imageView : UIImageView) {
        imageView.transform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
    }
}
