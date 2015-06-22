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
private let IconMessageTextWidth : CGFloat = 240.0
private let IconMessageMargin : CGFloat = 15.0
private let MessageButtonMargin : CGFloat = 15.0
private let BottomButtonHorizontalMargin : CGFloat = 12.0
private let BottomButtonVerticalMargin : CGFloat = 6.0


class IconMessageView : UIView {
    
    let styles : OEXStyles?
    let buttonFontStyle = OEXTextStyle(themeSansAtSize: 15.0)
    
    let iconView : UIImageView
    let messageView : UILabel
    var bottomButton : UIButton
    
    let container : UIView
    
    init(icon : Icon? = nil, message : String? = nil, buttonTitle : String? = nil, styles : OEXStyles?) {
        self.styles = styles
        
        container = UIView(frame: CGRectZero)
        iconView = UIImageView(frame: CGRectZero)
        messageView = UILabel(frame : CGRectZero)
        bottomButton = UIButton.buttonWithType(.System) as! UIButton
        super.init(frame: CGRectZero)
        
        self.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        setupViews(icon : icon, message : message, buttonTitle : buttonTitle)
    }

    required init(coder aDecoder: NSCoder) {
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
    
    var icon : Icon? {
        didSet {
            iconView.image = icon?.imageWithFontSize(IconMessageSize)
        }
    }
    
    var buttonTitle : String? {
        get {
            return bottomButton.titleLabel?.text
        }
        set {
            if let title = newValue {
                bottomButton.setTitle(title, forState: .Normal)
                addButtonBorder()
                
            }
            
        }
    }
    
    var messageStyle : OEXTextStyle  {
        let style = OEXMutableTextStyle(font: .ThemeSansBold, size: 14.0)
        style.color = styles?.neutralDark()
        style.alignment = .Center
        
        return style
    }
    
    private func setupViews(#icon : Icon?, message : String?, buttonTitle : String?) {
        self.icon = icon
        self.message = message
        self.buttonTitle = buttonTitle
        
        iconView.tintColor = styles?.neutralLight()
        
        messageView.numberOfLines = 0
        
        buttonFontStyle.asBold().applyToLabel(bottomButton.titleLabel)
        bottomButton.setTitleColor(styles?.neutralDark(), forState: .Normal)
        bottomButton.contentEdgeInsets = UIEdgeInsets(top: BottomButtonVerticalMargin, left: BottomButtonHorizontalMargin, bottom: BottomButtonVerticalMargin, right: BottomButtonHorizontalMargin)
        
        addSubview(container)
        container.addSubview(iconView)
        container.addSubview(messageView)
        container.addSubview(bottomButton)

    }
    
    private var hasBottomButton : Bool {
        return !(bottomButton.titleForState(.Normal)?.isEmpty ?? true)
    }
    
    override func updateConstraints() {
        container.snp_makeConstraints { (make) -> Void in
            make.center.equalTo(self)
            make.leading.greaterThanOrEqualTo(self)
            make.top.greaterThanOrEqualTo(self)
            make.trailing.lessThanOrEqualTo(self)
            make.bottom.lessThanOrEqualTo(self)
        }
        
        iconView.snp_updateConstraints { (make) -> Void in
            make.leading.equalTo(container)
            make.trailing.equalTo(container)
            make.top.equalTo(container)
        }
        
        messageView.snp_updateConstraints { (make) -> Void in
            make.top.equalTo(self.iconView.snp_bottom).offset(IconMessageMargin)
            make.centerX.equalTo(container)
            make.width.equalTo(IconMessageTextWidth)
            if !hasBottomButton {
                make.bottom.equalTo(container)
            }
        }
        
        if hasBottomButton {
            bottomButton.snp_makeConstraints { (make) -> Void in
                make.top.equalTo(self.messageView.snp_bottom).offset(MessageButtonMargin)
                make.centerX.equalTo(container)
                make.bottom.equalTo(container)
            }
        }
        super.updateConstraints()
    }
    
    func showNoConnectionError() {
        self.message = OEXLocalizedString("NETWORK_NOT_AVAILABLE_MESSAGE_TROUBLE", nil)
        self.icon = .InternetError
    }
    
    func addButtonBorder() {
        var bottomButtonLayer = bottomButton.layer
        bottomButtonLayer.cornerRadius = 4.0
        bottomButtonLayer.borderWidth = 1.0
        bottomButtonLayer.borderColor = styles?.neutralLight().CGColor
    }
}