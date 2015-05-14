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

class IconMessageView : UIView {
    
    let styles : OEXStyles?
    
    let iconView : UILabel
    let messageView : UILabel
    
    let container : UIView
    
    init(icon : Icon? = nil, message : String? = nil, styles : OEXStyles?) {
        self.styles = styles
        
        container = UIView(frame: CGRectZero)
        iconView = UILabel(frame: CGRectZero)
        messageView = UILabel(frame : CGRectZero)
        
        super.init(frame: CGRectZero)
        
        self.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        setupViews(icon : icon, message : message)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var message : String? {
        get {
            return messageView.text
        }
        set {
            messageView.attributedText = messageStyle.attributedStringWithText(newValue)
        }
    }
    
    var icon : Icon? {
        didSet {
            iconView.text = icon?.textRepresentation ?? ""
        }
    }
    
    private var messageStyle : OEXTextStyle  {
        let style = OEXMutableTextStyle(font: .ThemeSansBold, size: 14.0)
        style.color = styles?.neutralDark()
        style.alignment = .Center
        
        return style
    }
    
    private func setupViews(#icon : Icon?, message : String?) {
        self.icon = icon
        self.message = message
        
        iconView.font = Icon.fontWithSize(IconMessageSize)
        iconView.adjustsFontSizeToFitWidth = true
        iconView.minimumScaleFactor = 0.5
        iconView.textAlignment = .Center
        iconView.textColor = styles?.neutralLight()
        
        messageView.numberOfLines = 0
        
        addSubview(container)
        container.addSubview(iconView)
        container.addSubview(messageView)

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
            make.bottom.equalTo(container)
            make.width.equalTo(IconMessageTextWidth)
        }
        super.updateConstraints()
    }
    
    func showNoConnectionError() {
        self.message = OEXLocalizedString("NETWORK_NOT_AVAILABLE_MESSAGE_TROUBLE", nil)
        self.icon = .InternetError
    }
}