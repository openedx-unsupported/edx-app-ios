//
//  OfflineModeView.swift
//  edX
//
//  Created by Akiva Leffert on 5/15/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public class OfflineModeView: UIView {
    private let verticalMargin = StandardVerticalMargin
    
    private let bottomDivider : UIView = UIView(frame: CGRectZero)
    private let messageView : UILabel = UILabel(frame: CGRectZero)
    
    private var contrastColor : UIColor? {
        return OEXStyles.sharedStyles().secondaryDarkColor()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(bottomDivider)
        addSubview(messageView)
        
        
        backgroundColor = OEXStyles.sharedStyles().secondaryXLightColor()
        bottomDivider.backgroundColor = contrastColor
        
        messageView.attributedText = labelStyle.attributedStringWithText(Strings.offlineMode)

        addConstraints()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var labelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .SemiBold, size: .XXSmall, color: contrastColor)
    }
    
    private func addConstraints() {
        bottomDivider.snp_makeConstraints {make in
            make.bottom.equalTo(self)
            make.height.equalTo(OEXStyles.dividerSize())
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
        }
        
        messageView.snp_makeConstraints {make in
            make.top.equalTo(self).offset(verticalMargin)
            make.bottom.equalTo(self).offset(-verticalMargin)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.trailing.lessThanOrEqualTo(self).offset(StandardHorizontalMargin)
        }
    }
}
