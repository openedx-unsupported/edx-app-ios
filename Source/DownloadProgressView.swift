//
//  DownloadProgressView.swift
//  edX
//
//  Created by Akiva Leffert on 6/3/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public class DownloadProgressView: UIView {
    private let styles : OEXStyles
    
    private let verticalMargin = 3
    
    private let bottomDivider : UIView = UIView(frame: CGRectZero)
    
    private let viewButton = UIButton.buttonWithType(.System) as! UIButton
    private let spinner = SpinnerView(size : .Small, color : .Primary)
    private let messageView = UILabel(frame: CGRectZero)
    
    
    private var contrastColor : UIColor {
        return styles.primaryBaseColor()
    }
    
    private var labelStyle : OEXTextStyle {
        let style = OEXMutableTextStyle()
        style.size = 12
        style.font = .ThemeSansBold
        style.color = contrastColor
        return style
    }
    
    private var viewButtonStyle : ButtonStyle {
        let textStyle = OEXTextStyle(font: .ThemeSansBold, size: 14, color : contrastColor)
        return ButtonStyle(textStyle: textStyle, backgroundColor: nil, borderStyle: nil)
    }
    
    public init(frame : CGRect, styles : OEXStyles) {
        self.styles = styles
        super.init(frame : frame)
        
        addSubview(viewButton)
        addSubview(spinner)
        addSubview(messageView)
        addSubview(bottomDivider)
        
        viewButton.setTitle(OEXLocalizedString("VIEW", nil), forState: .Normal)
        viewButtonStyle.applyToButton(viewButton)
        
        messageView.attributedText = labelStyle.attributedStringWithText(OEXLocalizedString("VIDEO_DOWNLOADS_IN_PROGRESS", nil))
        
        backgroundColor = styles.primaryXLightColor()
        bottomDivider.backgroundColor = contrastColor
        
        bottomDivider.snp_makeConstraints {make in
            make.bottom.equalTo(self)
            make.height.equalTo(OEXStyles.dividerSize())
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
        }
        
        viewButton.snp_makeConstraints { make in
            make.trailing.equalTo(self.snp_trailing).offset(-10)
            make.centerY.equalTo(self)
            make.top.equalTo(self).offset(5)
            make.bottom.equalTo(self).offset(-5)
        }
        
        spinner.snp_makeConstraints { make in
            make.leading.equalTo(self).offset(10)
            make.centerY.equalTo(self)
        }
        
        messageView.snp_makeConstraints { make in
            make.centerY.equalTo(self)
            make.leading.equalTo(spinner.snp_trailing).offset(5)
        }
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
