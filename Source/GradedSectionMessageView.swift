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
    
    init() {
        super.init(frame: CGRectZero)
        messageLabel.numberOfLines = 0
        messageLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        addSubview(messageLabel)
        messageLabel.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(UIEdgeInsets(top: textInset, left: textInset, bottom: -textInset, right: -textInset))
        }
        messageLabel.attributedText = textStyle.attributedStringWithText(OEXLocalizedString("GRADED_CONTENT_WARNING", nil))
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var textInset : CGFloat {
        return OEXStyles.sharedStyles().standardHorizontalMargin()
    }
    
    private var textStyle : OEXTextStyle {
        return OEXTextStyle(font: .ThemeSans, size: 12, color: OEXStyles.sharedStyles().neutralBase())
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        messageLabel.preferredMaxLayoutWidth = (superview?.bounds.size.width ?? 0) - textInset * 2
    }
}
