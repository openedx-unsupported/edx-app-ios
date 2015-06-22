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
private let IconOffsetLeading = 20
private let CellOffsetTrailing : CGFloat = -10
private let TitleOffsetCenterY = -10
private let TitleOffsetLeading = 40
private let SubtitleOffsetCenterY = 10
private let DownloadCountOffsetTrailing = -2

private let SmallIconSize : CGFloat = 15
private let IconFontSize : CGFloat = 15

public class CourseOutlineItemView: UIView {
    
    private let fontStyle = OEXTextStyle(font: OEXTextFont.ThemeSans, size: 15.0)
    private let detailFontStyle = OEXMutableTextStyle(font: OEXTextFont.ThemeSans, size: 13.0)
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
        trailingCountLabel.text = count.map { "\($0)" } ?? ""
    }
    
    func setTrailingIconHidden(hidden : Bool) {
        self.trailingImageButton.hidden = hidden
        setNeedsUpdateConstraints()
    }
    
    init(trailingImageIcon : Icon? = nil) {
        super.init(frame: CGRectZero)
        
        fontStyle.applyToLabel(titleLabel)
        
        detailFontStyle.color = OEXStyles.sharedStyles().neutralBase()
        detailFontStyle.applyToLabel(subtitleLabel)
        
        leadingImageButton.tintColor = OEXStyles.sharedStyles().primaryAccentColor()
        leadingImageButton.setContentCompressionResistancePriority(1000, forAxis: .Horizontal)
        
        trailingImageButton.setImage(trailingImageIcon?.imageWithFontSize(IconFontSize), forState: .Normal)
        trailingImageButton.tintColor = OEXStyles.sharedStyles().neutralBase()
        trailingImageButton.contentEdgeInsets = UIEdgeInsetsMake(10, 10, 10, 10)
        trailingImageButton.setContentCompressionResistancePriority(1000, forAxis: .Horizontal)
        
        checkmark.image = Icon.Graded.imageWithFontSize(15)
        checkmark.tintColor = OEXStyles.sharedStyles().neutralBase()
        
        detailFontStyle.applyToLabel(trailingCountLabel)
        
        isGraded = false
        addSubviews()
    }
    
    func addActionForTrailingIconTap(action : AnyObject -> Void) -> OEXRemovable {
        return trailingImageButton.oex_addAction(action, forEvents: UIControlEvents.TouchUpInside)
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setTitleText(title : String) {
        titleLabel.text = title
    }
    
    func setDetailText(title : String) {
        subtitleLabel.text = title
        setNeedsUpdateConstraints()
    }
    
    func setContentIcon(icon : Icon?) {
        leadingImageButton.setImage(icon?.imageWithFontSize(IconFontSize), forState: .Normal)
        setNeedsUpdateConstraints()
    }
    
    override public func updateConstraints() {
        leadingImageButton.snp_updateConstraints { (make) -> Void in
            make.centerY.equalTo(self)
            let situationalleadingOffset = hasLeadingImageIcon ? IconOffsetLeading : 0
            make.leading.equalTo(self).offset(situationalleadingOffset)
            hasLeadingImageIcon ? make.leading.equalTo(self).offset(IconOffsetLeading) : make.leading.equalTo(self).offset(0)
            make.size.equalTo(IconSize)
        }
        
        let shouldOffsetTitle = !(subtitleLabel.text?.isEmpty ?? true)
        titleLabel.snp_updateConstraints { (make) -> Void in
            let titleOffset = shouldOffsetTitle ? TitleOffsetCenterY : 0
            make.centerY.equalTo(self).offset(titleOffset).constraint
            
            let situationalLeadingOffset  = hasLeadingImageIcon ? TitleOffsetLeading : 20
            make.leading.equalTo(leadingImageButton).offset(situationalLeadingOffset)
            make.trailing.equalTo(trailingImageButton.snp_leading).offset(TitleOffsetTrailing)
        }
        
        subtitleLabel.snp_updateConstraints { (make) -> Void in
            make.centerY.equalTo(self).offset(SubtitleOffsetCenterY).constraint
            make.leading.equalTo(titleLabel)
        }
        
        checkmark.snp_updateConstraints { (make) -> Void in
            make.centerY.equalTo(subtitleLabel.snp_centerY)
            make.leading.equalTo(subtitleLabel.snp_trailing).offset(5)
            make.size.equalTo(CGSizeMake(SmallIconSize, SmallIconSize))
        }
    
        trailingImageButton.snp_updateConstraints { (make) -> Void in
            make.trailing.equalTo(self.snp_trailing).offset(CellOffsetTrailing)
            make.centerY.equalTo(self)
        }
        
        trailingCountLabel.snp_updateConstraints { (make) -> Void in
            make.centerY.equalTo(trailingImageButton)
            make.trailing.equalTo(trailingImageButton.snp_centerX).offset(DownloadCountOffsetTrailing)
            make.size.equalTo(CGSizeMake(SmallIconSize, SmallIconSize))
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
    }
    
    public override class func requiresConstraintBasedLayout() -> Bool {
        return true
    }
}
