//
//  DownloadProgressView.swift
//  edX
//
//  Created by Akiva Leffert on 6/3/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

private let titleLabelCenterYOffset : CGFloat = -8
private let subtitleLabelCenterYOffset : CGFloat = 8

public class CourseOutlineHeaderView: UIView {
    private let styles : OEXStyles
    
    private let verticalMargin = 3
    
    private let bottomDivider : UIView = UIView(frame: CGRectZero)
    
    private let viewButton = UIButton.buttonWithType(.System) as! UIButton
    private let spinner = SpinnerView(size : .Small, color : .Primary)
    private let messageView = UILabel(frame: CGRectZero)
    private let subtitleLabel = UILabel(frame: CGRectZero)
    
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
    
    private var subtitleLabelStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(font: .ThemeSans, size: 15)
        return style
    }
    
    private var viewButtonStyle : ButtonStyle {
        let textStyle = OEXTextStyle(font: .ThemeSansBold, size: 14, color : contrastColor)
        return ButtonStyle(textStyle: textStyle, backgroundColor: nil, borderStyle: nil)
    }
    
    private var hasSubtitle : Bool {
        return !(subtitleLabel.text?.isEmpty ?? true)
    }
    
    private var isShowingSpinner : Bool {
        get {
            return !spinner.hidden
        }
        set {
            spinner.hidden = !newValue
        }
    }
    
    public var subtitleText : String? {
        get {
            return subtitleLabel.text
        }
        set {
            subtitleLabel.text = newValue
        }
    }
    
    public init(frame : CGRect, styles : OEXStyles, titleText : String? = nil , titleIsAttributed : Bool = false, subtitleText : String? = nil, shouldShowSpinner : Bool = false) {
        self.styles = styles
        super.init(frame : frame)
        
        addSubview(viewButton)
        addSubview(spinner)
        addSubview(messageView)
        addSubview(bottomDivider)
        addSubview(subtitleLabel)
        
        viewButton.setTitle(OEXLocalizedString("VIEW", nil), forState: .Normal)
        viewButtonStyle.applyToButton(viewButton)
        
        if let title = titleText {
            labelStyle.applyToLabel(messageView)
            if titleIsAttributed {
                messageView.attributedText = labelStyle.attributedStringWithText(title)
            }
            else {
                messageView.text = title
            }
        }
        
        subtitleLabelStyle.applyToLabel(subtitleLabel)
        if let subtitle = subtitleText {
            subtitleLabel.text = subtitle
        }
        else {
            subtitleLabel.text = ""
        }
        
        isShowingSpinner = shouldShowSpinner
        
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
            let situationalCenterYOffset = hasSubtitle ? titleLabelCenterYOffset : 0
            make.centerY.equalTo(self).offset(situationalCenterYOffset)
            let situationalLeadingOffset = isShowingSpinner ? 5 : 0
            make.leading.equalTo(spinner.snp_trailing).offset(situationalLeadingOffset)
        }
        
        subtitleLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self).offset(subtitleLabelCenterYOffset)
            let situationalLeadingOffset = isShowingSpinner ? 5 : 0
            make.leading.equalTo(spinner.snp_trailing).offset(situationalLeadingOffset)
        }
    }
    
    public func setViewButtonAction(action: (AnyObject) -> Void) {
        self.viewButton.oex_removeActions()
        self.viewButton.oex_addAction(action, forEvents: UIControlEvents.TouchUpInside)
        
    }

    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
