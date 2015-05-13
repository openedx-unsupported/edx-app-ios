//
//  EmptyMessageView.swift
//  edX
//
//  Created by Akiva Leffert on 5/12/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import UIKit

class EmptyMessageView : UIView {
    let styles : OEXStyles?
    let item : FontAwesome
    let message : String
    
    let iconView : UILabel
    let messageView : UILabel
    
    let container : UIView
    
    init(item : FontAwesome, message : String, styles : OEXStyles?) {
        self.item = item
        self.message = message
        self.styles = styles
        
        container = UIView(frame: CGRectZero)
        iconView = UILabel(frame: CGRectZero)
        messageView = UILabel(frame : CGRectZero)
        
        super.init(frame: CGRectZero)
        
        self.setTranslatesAutoresizingMaskIntoConstraints(false)
        
        setupViews(item : item, message : message)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var messageStyle : OEXTextStyle  {
        let style = OEXMutableTextStyle(font: .ThemeSansBold, size: 14.0)
        style.color = styles?.neutralDark()
        style.alignment = .Center
        
        return style
    }
    
    private func setupViews(#item : FontAwesome, message : String) {
        iconView.font = UIFont.fontAwesomeOfSize(80)
        iconView.text = item.rawValue
        iconView.adjustsFontSizeToFitWidth = true
        iconView.minimumScaleFactor = 0.5
        iconView.textAlignment = .Center
        iconView.textColor = styles?.neutralLight()
        
        messageView.numberOfLines = 0
        messageView.attributedText = messageStyle.attributedStringWithText(message)
        
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
            make.top.equalTo(self.iconView.snp_bottom).offset(15)
            make.centerX.equalTo(container)
            make.bottom.equalTo(container)
            make.width.equalTo(240)
        }
        super.updateConstraints()
    }
}