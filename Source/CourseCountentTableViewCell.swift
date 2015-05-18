//
//  CourseCountentTableViewCell.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 18/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class CourseCountentTableViewCell: UITableViewCell {

    let fontStyle = OEXTextStyle(font: OEXTextFont.ThemeSans, size: 15.0)
    let smallFontStyle = OEXTextStyle(font: OEXTextFont.ThemeSans, size: 13.0)
    var titleLabel = UILabel()
    var leftImageButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
    var rightImageButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
    var subtitleLabel = UILabel()
    
    internal func addSubviews() {
        self.addSubview(titleLabel)
        self.addSubview(leftImageButton)
        self.addSubview(rightImageButton)
        self.addSubview(subtitleLabel)
    }
    
    internal func setStyle(){
        fontStyle.applyToLabel(titleLabel)
        smallFontStyle.applyToLabel(subtitleLabel)
        
        leftImageButton.titleLabel?.font = Icon.fontWithSize(17)
        leftImageButton.setTitle(Icon.CourseVideoContent.textRepresentation, forState: .Normal)
        leftImageButton.setTitleColor(OEXStyles.sharedStyles()?.primaryBaseColor(), forState: .Normal)
        
        rightImageButton.titleLabel?.font = Icon.fontWithSize(13)
        rightImageButton.setTitle(Icon.ContentDownload.textRepresentation, forState: .Normal)
        rightImageButton.setTitleColor(OEXStyles.sharedStyles()?.neutralBase(), forState: .Normal)
        
        subtitleLabel.text = "15:51" // TEMPORARY
        subtitleLabel.textColor = OEXStyles.sharedStyles()?.neutralDark()
        
    }
    
    internal func setConstraints(){
        leftImageButton.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self)
            make.leading.equalTo(self).offset(UIConstants.ALIconOffsetLeading)
            make.size.equalTo(UIConstants.ALIconSize)
            
        }
        
        titleLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self).offset(UIConstants.ALTitleOffsetCenterY)
            make.leading.equalTo(leftImageButton).offset(UIConstants.ALTitleOffsetLeading)
            make.trailing.equalTo(rightImageButton.snp_leading).offset(10)
        }
        
        subtitleLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self).offset(12)
            make.leading.equalTo(leftImageButton).offset(UIConstants.ALTitleOffsetLeading)
        }
        
        rightImageButton.snp_makeConstraints { (make) -> Void in
            make.size.equalTo(CGSizeMake(15, 15))
            make.trailing.equalTo(self.snp_trailing).offset(UIConstants.ALCellOffsetTrailing)
            make.centerY.equalTo(self)
        }
        
    }

}
