//
//  CourseOutlineItemView.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 18/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

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
    
    private let horizontalMargin = OEXStyles.sharedStyles().standardHorizontalMargin()
    
    private let fontStyle = OEXTextStyle(weight: .Normal, size: .Base, color : OEXStyles.sharedStyles().neutralBlack())
    private let detailFontStyle = OEXTextStyle(weight: .Normal, size: .Small, color : OEXStyles.sharedStyles().neutralBase())
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let leadingImageButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
    private let trailingImageButton = UIButton.buttonWithType(UIButtonType.System) as! UIButton
    private let checkmark = UIImageView()
    private let trailingCountLabel = UILabel()
    
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
    
    var trailingIconColor : UIColor? {
        get {
            return trailingImageButton.tintColor
        }
        set {
            trailingImageButton.tintColor = newValue
        }
    }

    
    func useTrailingCount(count : Int?) {
        trailingCountLabel.attributedText = detailFontStyle.attributedStringWithText(count.map { "\($0)" })
        if let downloadableCount = self.trailingCountLabel.text, trailingCount = count {
            var downloadableCountMessage : NSString = OEXLocalizedStringPlural("DOWNLOAD", Float(trailingCount), nil)
            downloadableCountMessage = downloadableCountMessage.oex_formatWithParameters(["videoCount":downloadableCount])
            trailingImageButton.accessibilityHint = downloadableCountMessage as? String
        }
    }
    
    func setTrailingIconHidden(hidden : Bool) {
        self.trailingImageButton.hidden = hidden
        setNeedsUpdateConstraints()
    }
    
    init(trailingImageIcon : Icon? = nil) {
        super.init(frame: CGRectZero)
        
        leadingImageButton.tintColor = OEXStyles.sharedStyles().primaryBaseColor()
        leadingImageButton.setContentCompressionResistancePriority(1000, forAxis: .Horizontal)
        
        trailingImageButton.setImage(trailingImageIcon?.imageWithFontSize(IconFontSize), forState: .Normal)
        trailingImageButton.tintColor = OEXStyles.sharedStyles().neutralBase()
        trailingImageButton.contentEdgeInsets = UIEdgeInsetsMake(15, 10, 15, 10)
        trailingImageButton.setContentCompressionResistancePriority(1000, forAxis: .Horizontal)
        
        leadingImageButton.accessibilityTraits = UIAccessibilityTraitImage
        trailingImageButton.accessibilityLabel = OEXLocalizedString("DOWNLOAD", nil)
        
        checkmark.image = Icon.Graded.imageWithFontSize(15)
        checkmark.tintColor = OEXStyles.sharedStyles().neutralBase()
        
        isGraded = false
        addSubviews()
        setAccessibility()
    }
    
    func addActionForTrailingIconTap(action : AnyObject -> Void) -> OEXRemovable {
        return trailingImageButton.oex_addAction(action, forEvents: UIControlEvents.TouchUpInside)
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setTitleText(title : String?) {
        let displayTitle = (title?.isEmpty ?? true) ? OEXLocalizedString("UNTITLED", nil) : title
        titleLabel.attributedText = fontStyle.attributedStringWithText(displayTitle)
    }
    
    func setDetailText(title : String) {
        subtitleLabel.attributedText = detailFontStyle.attributedStringWithText(title)
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
            let situationalleadingOffset = hasLeadingImageIcon ? horizontalMargin : 0
            if hasLeadingImageIcon {
                make.leading.equalTo(self).offset(horizontalMargin)
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
                make.leading.equalTo(leadingImageButton.snp_trailing).offset(horizontalMargin)
            }
            else {
                make.leading.equalTo(self).offset(horizontalMargin)
            }
            make.trailing.equalTo(trailingImageButton.snp_leading).offset(TitleOffsetTrailing)
        }
        
        super.updateConstraints()
    }
    
    private func addSubviews() {
        addSubview(leadingImageButton)
        addSubview(trailingImageButton)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(checkmark)
        addSubview(trailingCountLabel)
        
        // For performance only add the static constraints once
        subtitleLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self).offset(SubtitleOffsetCenterY).constraint
            make.leading.equalTo(titleLabel)
        }
        
        checkmark.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(subtitleLabel.snp_centerY)
            make.leading.equalTo(subtitleLabel.snp_trailing).offset(5)
            make.size.equalTo(CGSizeMake(SmallIconSize, SmallIconSize))
        }
        
        trailingImageButton.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(self.snp_trailing).offset(CellOffsetTrailing)
            make.centerY.equalTo(self)
        }
        
        trailingCountLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(trailingImageButton)
            make.trailing.equalTo(trailingImageButton.snp_centerX).offset(DownloadCountOffsetTrailing)
            make.size.equalTo(CGSizeMake(SmallIconSize, SmallIconSize))
        }
    }
    
    public override class func requiresConstraintBasedLayout() -> Bool {
        return true
    }
    
    private func setAccessibility() {
        trailingCountLabel.isAccessibilityElement = false
        subtitleLabel.isAccessibilityElement = false
    }
    
}
