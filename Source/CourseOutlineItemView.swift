//
//  CourseOutlineItemView.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 18/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

private let TitleOffsetTrailing = -10
private let IconSize = CGSizeMake(25, 25)
private let IconOffsetLeading = 20
private let CellOffsetTrailing = -10
private let TitleOffsetCenterY = -10
private let TitleOffsetLeading = 40
private let SubtitleOffsetCenterY = 10

public class CourseOutlineItemView: UIView {
    
    private let fontStyle = OEXTextStyle(font: OEXTextFont.ThemeSans, size: 15.0)
    private let detailFontStyle = OEXMutableTextStyle(font: OEXTextFont.ThemeSans, size: 13.0)
    private let titleLabel = UILabel()
    private let leadingImageButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
    private let checkmark = UILabel()
    private var hasLeadingImageIcon = false
    
    public var titleLabelCenterYConstraint : Constraint?
    public var isGraded : Bool? {
        get {
            return !checkmark.hidden
        }
        set {
            checkmark.hidden = !(newValue!)
        }
    }
    
    var leadingIconColor : UIColor! {
        get {
            return leadingImageButton.titleColorForState(.Normal)!
        }
        set {
            leadingImageButton.setTitleColor(newValue, forState:.Normal)
        }
    }
    
    private let trailingImageButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
    var trailingIconColor : UIColor {
        get {
            return trailingImageButton.titleColorForState(.Normal)!
        }
        set {
            trailingImageButton.setTitleColor(newValue, forState:.Normal)
        }
    }
    
    func useTitleStyle(style : OEXTextStyle) {
        style.applyToLabel(titleLabel)
    }
    
    let subtitleLabel = UILabel()
    
    init(title : String? = nil, subtitle : String? = nil, leadingImageIcon : Icon?, trailingImageIcon : Icon? = nil, isGraded : Bool = false) {
        super.init(frame: CGRectZero)
        
        self.isGraded = isGraded
        
        fontStyle.applyToLabel(titleLabel)
        title.map { titleLabel.text = $0 }
        
        detailFontStyle.color = OEXStyles.sharedStyles().neutralBase()
        detailFontStyle.applyToLabel(subtitleLabel)
        subtitle.map { subtitleLabel.text = $0 }
        
        hasLeadingImageIcon = leadingImageIcon != nil
            
        leadingImageButton.titleLabel?.font = Icon.fontWithSize(15)
        leadingImageButton.setTitle(leadingImageIcon?.textRepresentation, forState: .Normal)
        leadingImageButton.setTitleColor(OEXStyles.sharedStyles().primaryAccentColor(), forState: .Normal)
        
        trailingImageButton.titleLabel?.font = Icon.fontWithSize(13)
        trailingImageButton.setTitle(trailingImageIcon?.textRepresentation, forState: .Normal)
        trailingImageButton.setTitleColor(OEXStyles.sharedStyles().neutralBase(), forState: .Normal)
        
        checkmark.font = Icon.fontWithSize(15)
        checkmark.textColor = OEXStyles.sharedStyles().neutralBase()
        checkmark.text = Icon.Graded.textRepresentation
        
        
        addSubviews()
        setConstraints()
        
    }
    
    func addActionForTrailingIconTap(action : AnyObject -> Void) -> OEXRemovable {
        return trailingImageButton.oex_addAction(action, forEvents: UIControlEvents.TouchUpInside)
    }
    
    required public init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setTitleText(title : String)
    {
        titleLabel.text = title
    }
    
    private func setConstraints()
    {
        leadingImageButton.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self)
            let situationalleadingOffset = hasLeadingImageIcon ? IconOffsetLeading : 0
            make.leading.equalTo(self).offset(situationalleadingOffset)
            hasLeadingImageIcon ? make.leading.equalTo(self).offset(IconOffsetLeading) : make.leading.equalTo(self).offset(0)
            make.size.equalTo(IconSize)
        }
        
        titleLabel.snp_makeConstraints { (make) -> Void in
            titleLabelCenterYConstraint = make.centerY.equalTo(self).offset(TitleOffsetCenterY).constraint
            let situationalLeadingOffset  = hasLeadingImageIcon ? TitleOffsetLeading : 20
            make.leading.equalTo(leadingImageButton).offset(situationalLeadingOffset)
            make.trailing.equalTo(trailingImageButton.snp_leading).offset(TitleOffsetTrailing)
        }
        
        subtitleLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self).offset(SubtitleOffsetCenterY).constraint
            make.leading.equalTo(titleLabel)
        }
        
        trailingImageButton.snp_makeConstraints { (make) -> Void in
            make.size.equalTo(CGSizeMake(15, 15))
            make.trailing.equalTo(self.snp_trailing).offset(CellOffsetTrailing)
            make.centerY.equalTo(self)
        }
        
        checkmark.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(subtitleLabel.snp_centerY)
            make.leading.equalTo(subtitleLabel.snp_trailing).offset(5)
            make.size.equalTo(CGSizeMake(15, 15))
        }
        
        
    }
    
    private func addSubviews() {
        addSubview(leadingImageButton)
        addSubview(trailingImageButton)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(checkmark)
    }
}
