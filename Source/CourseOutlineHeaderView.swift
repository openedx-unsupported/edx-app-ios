//
//  DownloadProgressView.swift
//  edX
//
//  Created by Akiva Leffert on 6/3/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public class CourseOutlineHeaderView: UIView {
    private let styles : OEXStyles
    
    private let verticalMargin = 3
    private let buttonIconMargin: CGFloat = 21  // Lines it up with the download video icon. This is fragile and would be better to eventually use the same source of truth for positioning.
    private let buttonIconSize: CGFloat = 16

    private let bottomDivider : UIView = UIView(frame: CGRect.zero)
    
    private let viewButton = UIButton(type: .system)
    private let messageView = UIView(frame: CGRect.zero)
    private let titleLabel = UILabel(frame: CGRect.zero)
    private let subtitleLabel = UILabel(frame: CGRect.zero)

    private var contrastColor : UIColor {
        return styles.neutralWhiteT()
    }
    
    private var labelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .semiBold, size: .base, color: contrastColor)
    }
    
    private var subtitleLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color : contrastColor)
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
            viewButton.accessibilityValue = newValue
        }
    }
    
    public init(frame : CGRect, styles : OEXStyles, titleText : String? = nil, subtitleText : String? = nil) {
        self.styles = styles
        super.init(frame : frame)
        
        backgroundColor = styles.primaryBaseColor()

        addSubviews()
        configureSubviews(title: titleText, subtitle: subtitleText, dividerColor: contrastColor)
        
        configureAccessibility(title: titleText, subtitle: subtitleText)
    }
    
    private func addSubviews() {
        messageView.addSubview(titleLabel)
        messageView.addSubview(subtitleLabel)

        addSubview(messageView)
        addSubview(bottomDivider)
        addSubview(viewButton) // Keep this on top to catch taps anywhere in this view
        
        bringSubviewToFront(viewButton) // Ensure this is on top to catch taps anywhere in this view
    }
    
    private func configureSubviews(title: String?, subtitle: String?, dividerColor: UIColor) {
        titleLabel.attributedText = labelStyle.attributedString(withText: title)
        subtitleLabel.attributedText = subtitleLabelStyle.attributedString(withText: subtitle)
        bottomDivider.backgroundColor = dividerColor

        let buttonIcon = Icon.ChevronRight.imageWithFontSize(size: buttonIconSize)
        configureViewButton(icon: buttonIcon)

        setConstraints(buttonIconWidth: buttonIcon.size.width)
    }
    
    private func configureViewButton(icon: UIImage) {
        viewButton.setImage(icon, for: .normal)
        viewButton.tintColor = styles.accentAColor()
        viewButton.contentHorizontalAlignment = .trailing
        viewButton.contentEdgeInsets = UIEdgeInsets(top: 0, left: buttonIconMargin, bottom: 0, right: buttonIconMargin)
    }
    
    private func setConstraints(buttonIconWidth: CGFloat) {
        bottomDivider.snp.makeConstraints { make in
            make.bottom.equalTo(self)
            make.height.equalTo(OEXStyles.dividerSize())
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
        }
        
        viewButton.snp.makeConstraints { make in
            make.trailing.equalTo(self)
            make.leading.equalTo(self)
            make.top.equalTo(self)
            make.bottom.equalTo(self)
        }
        
        messageView.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(self)
            make.bottom.lessThanOrEqualTo(self)
            make.centerY.equalTo(self)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.trailing.lessThanOrEqualTo(viewButton).offset(-buttonIconMargin - buttonIconWidth - 10).priority(.high) // 10pt away from the button icon once the icon is positioned correctly
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(messageView)
            make.leading.equalTo(messageView)
            make.trailing.equalTo(messageView)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom)
            make.bottom.equalTo(messageView)
            make.leading.equalTo(messageView)
            make.trailing.equalTo(messageView)
        }
    }

    private func configureAccessibility(title: String?, subtitle: String?) {
        bottomDivider.isAccessibilityElement = false
        messageView.isAccessibilityElement = false
        titleLabel.isAccessibilityElement = false
        subtitleLabel.isAccessibilityElement = false

        accessibilityIdentifier = "CourseOutlineHeaderView:view"
        viewButton.accessibilityIdentifier = "CourseOutlineHeaderView:view-button"
        viewButton.accessibilityLabel = title
        viewButton.accessibilityValue = subtitle
        viewButton.accessibilityHint = Strings.Accessibility.resumeHint
    }
    
    public func setViewButtonAction(action: @escaping (AnyObject) -> Void) {
        viewButton.oex_removeAllActions()
        viewButton.oex_addAction(action, for: UIControl.Event.touchUpInside)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
