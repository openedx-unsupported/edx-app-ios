//
//  DownloadProgressView.swift
//  edX
//
//  Created by Akiva Leffert on 6/3/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

private let titleLabelCenterYOffset : CGFloat = -10
private let subtitleLabelCenterYOffset : CGFloat = 8

public class CourseOutlineHeaderView: UIView {
    private let styles : OEXStyles
    
    private let verticalMargin = 3
    
    private let bottomDivider : UIView = UIView(frame: CGRect.zero)
    
    private let viewButton = UIButton(type: .system)
    private let messageView = UILabel(frame: CGRect.zero)
    private let subtitleLabel = UILabel(frame: CGRect.zero)
    
    private var contrastColor : UIColor {
        return styles.primaryBaseColor()
    }
    
    private var labelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color: contrastColor)
    }
    
    private var subtitleLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color : OEXStyles.shared().neutralBlack())
    }
    
    private var viewButtonStyle : ButtonStyle {
        let textStyle = OEXTextStyle(weight: .normal, size: .large, color : contrastColor)
        return ButtonStyle(textStyle: textStyle, backgroundColor: nil, borderStyle: nil)
    }
    
    private var hasSubtitle : Bool {
        return !(subtitleLabel.text?.isEmpty ?? true)
    }
    
    public var subtitleText : String? {
        get {
            return subtitleLabel.text
        }
        set {
            subtitleLabel.attributedText = subtitleLabelStyle.attributedString(withText: newValue)
        }
    }
    
    public init(frame : CGRect, styles : OEXStyles, titleText : String? = nil, subtitleText : String? = nil) {
        self.styles = styles
        super.init(frame : frame)
        
        addSubview(viewButton)
        addSubview(messageView)
        addSubview(bottomDivider)
        addSubview(subtitleLabel)
        
        viewButton.applyButtonStyle(style: viewButtonStyle, withTitle : Strings.view)
        
        messageView.attributedText = labelStyle.attributedString(withText: titleText)
        subtitleLabel.attributedText = subtitleLabelStyle.attributedString(withText: subtitleText)
        
        backgroundColor = styles.primaryXLightColor()
        bottomDivider.backgroundColor = contrastColor
        
        bottomDivider.snp_makeConstraints {make in
            make.bottom.equalTo(self)
            make.height.equalTo(OEXStyles.dividerSize())
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
        }
        
        viewButton.snp_makeConstraints { make in
            make.trailing.equalTo(self.snp_trailing).offset(-StandardHorizontalMargin)
            make.centerY.equalTo(self)
            make.top.equalTo(self).offset(5)
            make.bottom.equalTo(self).offset(-5)
        }

        viewButton.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: UILayoutConstraintAxis.horizontal)
        
        messageView.snp_makeConstraints { make in
            let situationalCenterYOffset = hasSubtitle ? titleLabelCenterYOffset : 0
            make.centerY.equalTo(self).offset(situationalCenterYOffset)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
        }
        
        subtitleLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self).offset(subtitleLabelCenterYOffset)
            make.leading.equalTo(messageView)
            make.trailing.lessThanOrEqualTo(viewButton.snp_leading).offset(-10)
        }
        subtitleLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, for: UILayoutConstraintAxis.horizontal)
    }
    
    public func setViewButtonAction(action: @escaping (AnyObject) -> Void) {
        viewButton.oex_removeAllActions()
        viewButton.oex_addAction(action, for: UIControlEvents.touchUpInside)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
