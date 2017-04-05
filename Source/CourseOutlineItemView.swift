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
private let IconSize = CGSize(width: 25, height: 25)
private let CellOffsetTrailing : CGFloat = -10
private let TitleOffsetCenterY = -10
private let TitleOffsetLeading = 40
private let SubtitleOffsetCenterY = 10
private let DownloadCountOffsetTrailing = -2

private let SmallIconSize : CGFloat = 15
private let IconFontSize : CGFloat = 15

public class CourseOutlineItemView: UIView {
    static let detailFontStyle = OEXTextStyle(weight: .normal, size: .small, color : OEXStyles.shared().neutralBase())
    
    private let fontStyle = OEXTextStyle(weight: .normal, size: .base, color : OEXStyles.shared().neutralBlack())
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let leadingImageButton = UIButton(type: UIButtonType.system)
    private let checkmark = UIImageView()
    private let trailingContainer = UIView()
    
    var hasLeadingImageIcon :Bool {
        return leadingImageButton.image(for: .normal) != nil
    }
    
    public var isGraded : Bool? {
        get {
            return !checkmark.isHidden
        }
        set {
            checkmark.isHidden = !(newValue!)
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
        return icon?.imageWithFontSize(size: IconFontSize)
    }
    
    init() {
        super.init(frame: CGRect.zero)
        
        leadingImageButton.tintColor = OEXStyles.shared().primaryBaseColor()
        leadingImageButton.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .horizontal)
        trailingContainer.setContentCompressionResistancePriority(UILayoutPriorityDefaultHigh, for: .horizontal)
        
        leadingImageButton.accessibilityTraits = UIAccessibilityTraitImage
        titleLabel.setContentHuggingPriority(UILayoutPriorityDefaultLow, for: .horizontal)
        
        checkmark.image = Icon.Graded.imageWithFontSize(size: 10)
        checkmark.tintColor = OEXStyles.shared().primaryBaseColor()
        
        isGraded = false
        addSubviews()
        setAccessibility()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setTitleText(title : String?) {
        titleLabel.attributedText = fontStyle.attributedString(withText: title)
    }
    
    func setDetailText(title : String) {
        subtitleLabel.attributedText = CourseOutlineItemView.detailFontStyle.attributedString(withText: title)
        setNeedsUpdateConstraints()
    }
    
    func setContentIcon(icon : Icon?) {
        leadingImageButton.setImage(icon?.imageWithFontSize(size: IconFontSize), for: .normal)
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
            make.centerY.equalTo(self).offset(SubtitleOffsetCenterY)
            make.leading.equalTo(titleLabel)
            make.trailing.lessThanOrEqualTo(trailingContainer.snp_leading).offset(TitleOffsetTrailing)
        }
        
        checkmark.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(subtitleLabel.snp_centerY)
            make.leading.equalTo(subtitleLabel.snp_trailing).offset(5)
            make.size.equalTo(CGSize(width: SmallIconSize, height: SmallIconSize))
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
    
    public override class var requiresConstraintBasedLayout: Bool {
        return true
    }
    
    private func setAccessibility() {
        subtitleLabel.isAccessibilityElement = false
    }
    
}
