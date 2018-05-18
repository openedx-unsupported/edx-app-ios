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
        return OEXTextStyle(weight :.normal, size : .base, color : OEXStyles.shared().neutralDark())
    }
    
    private let iconView : UIImageView
    private let messageView : UILabel
    private var bottomButton : UIButton
    
    private let container : UIView
    
    init(icon : Icon? = nil, message : String? = nil) {
        
        container = UIView(frame: .zero)
        iconView = UIImageView(frame: .zero)
        messageView = UILabel(frame : .zero)
        bottomButton = UIButton(type: .system)
        super.init(frame: .zero)
        
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
            messageView.attributedText = newValue.map { messageStyle.attributedString(withText: $0) }
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
            iconView.image = icon?.imageWithFontSize(size: IconMessageSize)
        }
    }
    
    private var buttonTitle : String? {
        get {
            return bottomButton.titleLabel?.text
        }
        set {
            if let title = newValue {
                let attributedTitle = buttonFontStyle.withWeight(.semiBold).attributedString(withText: title)
                bottomButton.setAttributedTitle(attributedTitle, for: .normal)
                addButtonBorder()
            }
            else {
                bottomButton.setAttributedTitle(nil, for: .normal)
            }
            
        }
    }
    
    var messageStyle : OEXTextStyle  {
        let style = OEXMutableTextStyle(weight: .semiBold, size: .base, color : OEXStyles.shared().neutralDark())
        style.alignment = .center
        
        return style
    }
    
    private func setupViews(icon : Icon?, message : String?) {
        self.icon = icon
        self.message = message
        
        iconView.tintColor = OEXStyles.shared().neutralLight()
        
        messageView.numberOfLines = 0
        
        bottomButton.contentEdgeInsets = UIEdgeInsets(top: BottomButtonVerticalMargin, left: BottomButtonHorizontalMargin, bottom: BottomButtonVerticalMargin, right: BottomButtonHorizontalMargin)
        
        addSubview(container)
        container.addSubview(iconView)
        container.addSubview(messageView)
        container.addSubview(bottomButton)

    }
    
    override func updateConstraints() {
        container.snp.makeConstraints { make in
            make.center.equalTo(self)
            make.leading.greaterThanOrEqualTo(self)
            make.trailing.lessThanOrEqualTo(self)
            make.top.greaterThanOrEqualTo(self)
            make.bottom.lessThanOrEqualTo(self)
        }
        
        iconView.snp.remakeConstraints { make in
            make.leading.equalTo(container)
            make.trailing.equalTo(container)
            make.top.equalTo(container)
        }
        
        messageView.snp.remakeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(IconMessageMargin)
            make.centerX.equalTo(container)
            make.width.equalTo(IconMessageTextWidth)
            if !hasBottomButton {
                make.bottom.equalTo(container)
            }
        }
        
        if hasBottomButton {
            bottomButton.snp.remakeConstraints { make in
                make.top.equalTo(messageView.snp.bottom).offset(MessageButtonMargin)
                make.centerX.equalTo(container)
                make.bottom.equalTo(container)
            }
        }
        super.updateConstraints()
    }
    
    func setupForOutdatedVersionError() {
        message = Strings.VersionUpgrade.outDatedMessage
        icon = .Warning
        
        buttonInfo = MessageButtonInfo(title : Strings.versionUpgradeUpdate)
        {
            if let URL = OEXConfig.shared().appUpgradeConfig.iOSAppStoreURL() {
                UIApplication.shared.openURL(URL as URL)
            }
        }
    }
    
    func showError(message: NSAttributedString?, icon: Icon?) {
        attributedMessage = message
        self.icon = icon ?? .UnknownError
        
        if let controller = self.container.firstAvailableUIViewController() as? LoadStateViewController, controller.isSupportingReload() {
            buttonInfo = MessageButtonInfo(title : Strings.reload)
            {
                controller.loadStateViewReload()
            }
        }
    }
    
    func showError(message: String?, icon: Icon?) {
        let attributedMessage = messageStyle.attributedString(withText: message)
        showError(message: attributedMessage, icon: icon)
    }
    
    var buttonInfo : MessageButtonInfo? {
        didSet {
            bottomButton.oex_removeAllActions()
            buttonTitle = buttonInfo?.title
            if let action = buttonInfo?.action {
                bottomButton.oex_addAction({button in action() }, for: .touchUpInside)
            }
        }
    }
    
    func addButtonBorder() {
        hasBottomButton = true
        setNeedsUpdateConstraints()
        let bottomButtonLayer = bottomButton.layer
        bottomButtonLayer.cornerRadius = 4.0
        bottomButtonLayer.borderWidth = 1.0
        bottomButtonLayer.borderColor = OEXStyles.shared().neutralLight().cgColor
    }
    
    func rotateImageViewClockwise(imageView : UIImageView) {
        imageView.transform = CGAffineTransform(rotationAngle: CGFloat(Double.pi/2))
    }
}
