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
    
    let fontStyle = OEXTextStyle(font: OEXTextFont.ThemeSans, size: 15.0)
    let detailFontStyle = OEXMutableTextStyle(font: OEXTextFont.ThemeSans, size: 13.0)
    let titleLabel = UILabel()
    let leadingImageButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
    let checkmark = UILabel()
    
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
    
    let trailingImageButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
    var trailingIconColor : UIColor {
        get {
            return trailingImageButton.titleColorForState(.Normal)!
        }
        set {
            trailingImageButton.setTitleColor(newValue, forState:.Normal)
        }
    }
    
    let subtitleLabel = UILabel()
    
    init(title : String, subtitle : String, leadingImageIcon : Icon, trailingImageIcon : Icon?, isGraded : Bool = false){
        super.init(frame: CGRectZero)
        
        self.isGraded = isGraded
        
        fontStyle.applyToLabel(titleLabel)
        titleLabel.text = title
        
        detailFontStyle.color = OEXStyles.sharedStyles().neutralBase()
        detailFontStyle.applyToLabel(subtitleLabel)
        subtitleLabel.text = subtitle ?? ""
        
        leadingImageButton.titleLabel?.font = Icon.fontWithSize(15)
        
        leadingImageButton.setTitle(leadingImageIcon.textRepresentation, forState: .Normal)
        leadingImageButton.setTitleColor(OEXStyles.sharedStyles().primaryAccentColor(), forState: .Normal)
        
        trailingImageButton.titleLabel?.font = Icon.fontWithSize(13)
        trailingImageButton.setTitle(trailingImageIcon?.textRepresentation, forState: .Normal)
        trailingImageButton.setTitleColor(OEXStyles.sharedStyles().neutralBase(), forState: .Normal)
        
        checkmark.font = Icon.fontWithSize(15)
        checkmark.textColor = OEXStyles.sharedStyles().neutralBase()
        checkmark.text = Icon.Checkmark.textRepresentation
        
        
        addSubviews()
        setConstraints()
        
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
            make.leading.equalTo(self).offset(IconOffsetLeading)
            make.size.equalTo(IconSize)
           
        }
        
        titleLabel.snp_makeConstraints { (make) -> Void in
            titleLabelCenterYConstraint = make.centerY.equalTo(self).offset(TitleOffsetCenterY).constraint
            make.leading.equalTo(leadingImageButton).offset(TitleOffsetLeading)
            make.trailing.equalTo(trailingImageButton.snp_leading).offset(TitleOffsetTrailing)
        }
        
        subtitleLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self).offset(SubtitleOffsetCenterY).constraint
            make.leading.equalTo(leadingImageButton).offset(TitleOffsetLeading)
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