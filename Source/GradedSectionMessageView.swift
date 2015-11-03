//
//  GradedSectionMessageView.swift
//  edX
//
//  Created by Akiva Leffert on 6/6/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class GradedSectionMessageView: UIView {
    let messageLabel = UILabel()
    let separator = UIView()
    
    init() {
        super.init(frame: CGRectZero)
        messageLabel.numberOfLines = 0
        messageLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        addSubview(messageLabel)
        
        separator.backgroundColor = textStyle.color
        addSubview(separator)
        
        self.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        
        messageLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self).offset(textInset)
            make.trailing.equalTo(self).offset(-textInset)
            make.top.equalTo(self).offset(textInset)
            make.bottom.equalTo(self).offset(-textInset)
        }
        messageLabel.attributedText = textStyle.attributedStringWithText(Strings.gradedContentWarning)
        
        separator.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.bottom.equalTo(self)
            make.height.equalTo(OEXStyles.dividerSize())
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var textInset : CGFloat {
        return StandardHorizontalMargin
    }
    
    private var textStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Small, color: OEXStyles.sharedStyles().neutralDark())
    }
}
