//
//  CourseOutlineItemView.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 18/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

protocol CourseBlockContainerCell {
    var block : CourseBlock? { get }
    func applyStyle(style : TableCellStyle)
}

private let TitleOffsetTrailing = -10
private let SubtitleOffsetTrailing = -10
private let IconSize = CGSizeMake(25, 25)
private let CellOffsetTrailing : CGFloat = -10
private let TitleOffsetCenterY = -10
private let TitleOffsetLeading = 40
private let SubtitleOffsetCenterY = 10
private let DownloadCountOffsetTrailing = -2

private let SmallIconSize : CGFloat = 15
private let IconFontSize : CGFloat = 15

public class CourseOutlineItemView: UIView {
    static let detailFontStyle = OEXTextStyle(weight: .Normal, size: .Small, color : OEXStyles.sharedStyles().neutralBase())
    
    private let fontStyle = OEXTextStyle(weight: .Normal, size: .Base, color : OEXStyles.sharedStyles().neutralBlack())
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let leadingImageButton = UIButton(type: UIButtonType.System)
    private let checkmark = UIImageView()
    private let trailingContainer = UIView()
    
    var hasLeadingImageIcon :Bool {
        return leadingImageButton.imageForState(.Normal) != nil
    }
    
    public var isGraded : Bool? {
        get {
            return !checkmark.hidden
        }
        set {
            checkmark.hidden = !(newValue!)
            setNeedsUpdateConstraints()
        }
    }
    
    var leadingIconColor : UIColor? {
        get {
            return leadingImageButton.tintColor
        }
        set {
            leadingImageButton.tintColor = newValue
        }
    }

    func imageForIcon(icon : Icon?) -> UIImage? {
        return icon?.imageWithFontSize(IconFontSize)
    }
    
    init() {
        super.init(frame: CGRectZero)
        
        leadingImageButton.tintColor = OEXStyles.sharedStyles().primaryBaseColor()
        leadingImageButton.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, forAxis: .Horizontal)
        trailingContainer.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, forAxis: .Horizontal)
        
        leadingImageButton.accessibilityTraits = UIAccessibilityTraitImage
        titleLabel.setContentHuggingPriority(UILayoutPriorityDefaultLow, forAxis: .Horizontal)
        
        checkmark.image = Icon.Graded.imageWithFontSize(10)
        checkmark.tintColor = OEXStyles.sharedStyles().primaryBaseColor()
        
        isGraded = false
        addSubviews()
        setAccessibility()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setTitleText(title : String?) {
        titleLabel.attributedText = fontStyle.attributedStringWithText(title)
    }
    
    func setDetailText(title : String) {
        subtitleLabel.attributedText = CourseOutlineItemView.detailFontStyle.attributedStringWithText(title)
        setNeedsUpdateConstraints()
    }
    
    func setContentIcon(icon : Icon?) {
        leadingImageButton.setImage(icon?.imageWithFontSize(IconFontSize), forState: .Normal)
        setNeedsUpdateConstraints()
        if let accessibilityText = icon?.accessibilityText {
            leadingImageButton.accessibilityLabel = accessibilityText
        }
    }
    
    override public func updateConstraints() {
        leadingImageButton.snp_updateConstraints { (make) -> Void in
            make.centerY.equalTo(self)
            if hasLeadingImageIcon {
                make.leading.equalTo(self).offset(StandardHorizontalMargin)
            }
            else {
                make.leading.equalTo(self)
            }
            make.size.equalTo(IconSize)
        }
        
        let shouldOffsetTitle = !(subtitleLabel.text?.isEmpty ?? true)
        titleLabel.snp_updateConstraints { (make) -> Void in
            let titleOffset = shouldOffsetTitle ? TitleOffsetCenterY : 0
            make.centerY.equalTo(self).offset(titleOffset)
            if hasLeadingImageIcon {
                make.leading.equalTo(leadingImageButton.snp_trailing).offset(StandardHorizontalMargin)
            }
            else {
                make.leading.equalTo(self).offset(StandardHorizontalMargin)
            }
            make.trailing.lessThanOrEqualTo(trailingContainer.snp_leading).offset(TitleOffsetTrailing)
        }
        
        super.updateConstraints()
    }
    
    private func addSubviews() {
        addSubview(leadingImageButton)
        addSubview(trailingContainer)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(checkmark)
        
        // For performance only add the static constraints once
        subtitleLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self).offset(SubtitleOffsetCenterY).constraint
            make.leading.equalTo(titleLabel)
            make.trailing.lessThanOrEqualTo(trailingContainer.snp_leading).offset(TitleOffsetTrailing)
        }
        
        checkmark.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(subtitleLabel.snp_centerY)
            make.leading.equalTo(subtitleLabel.snp_trailing).offset(5)
            make.size.equalTo(CGSizeMake(SmallIconSize, SmallIconSize))
        }
        
        trailingContainer.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(self.snp_trailing).offset(CellOffsetTrailing)
            make.centerY.equalTo(self)
        }
    }
    
    var trailingView : UIView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let view = trailingView {
                trailingContainer.addSubview(view)
                view.snp_makeConstraints {make in
                    // required to prevent long titles from compressing this
                    make.edges.equalTo(trailingContainer).priorityRequired()
                }
            }
            setNeedsLayout()
        }
    }
    
    public override class func requiresConstraintBasedLayout() -> Bool {
        return true
    }
    
    private func setAccessibility() {
        subtitleLabel.isAccessibilityElement = false
    }
    
}
