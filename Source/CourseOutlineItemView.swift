//
//  CourseOutlineItemView.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 18/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

private let ALIconSize = CGSizeMake(25, 25)
private let ALIconOffsetLeading = 20
private let ALCellOffsetTrailing = -10
private let ALTitleOffsetCenterY = -5
private let ALTitleOffsetLeading = 40

class CourseOutlineItemView: UIView {
    
    let fontStyle = OEXTextStyle(font: OEXTextFont.ThemeSans, size: 15.0)
    let detailFontStyle = OEXMutableTextStyle(font: OEXTextFont.ThemeSans, size: 13.0)
    let titleLabel = UILabel()
    let leadingImageButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
    
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
    
    init(title : String, subtitle : String, leadingImageIcon : Icon, trailingImageIcon : Icon?){
        super.init(frame: CGRectZero)
        
        fontStyle.applyToLabel(titleLabel)
        titleLabel.text = title
        
        detailFontStyle.color = OEXStyles.sharedStyles().neutralBase()
        detailFontStyle.applyToLabel(subtitleLabel)
        subtitleLabel.text = subtitle ?? ""
        
        leadingImageButton.titleLabel?.font = Icon.fontWithSize(15)
        
        leadingImageButton.setTitle(leadingImageIcon.textRepresentation, forState: .Normal)
        leadingImageButton.setTitleColor(OEXStyles.sharedStyles().primaryBaseColor(), forState: .Normal)
        
        trailingImageButton.titleLabel?.font = Icon.fontWithSize(13)
        trailingImageButton.setTitle(trailingImageIcon?.textRepresentation, forState: .Normal)
        trailingImageButton.setTitleColor(OEXStyles.sharedStyles().neutralBase(), forState: .Normal)
        
        addSubviews()
        setConstraints()
        
    }
    
    required init(coder aDecoder: NSCoder) {
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
            make.leading.equalTo(self).offset(ALIconOffsetLeading)
            make.size.equalTo(ALIconSize)
        }
        
        titleLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self).offset(ALTitleOffsetCenterY)
            make.leading.equalTo(leadingImageButton).offset(ALTitleOffsetLeading)
            make.trailing.equalTo(trailingImageButton.snp_leading).offset(10)
        }
        
        subtitleLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self).offset(12)
            make.leading.equalTo(leadingImageButton).offset(ALTitleOffsetLeading)
        }
        
        trailingImageButton.snp_makeConstraints { (make) -> Void in
            make.size.equalTo(CGSizeMake(15, 15))
            make.trailing.equalTo(self.snp_trailing).offset(ALCellOffsetTrailing)
            make.centerY.equalTo(self)
        }
        
        
    }
    
    private func addSubviews() {
        addSubview(leadingImageButton)
        addSubview(trailingImageButton)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
    }
}