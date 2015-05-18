//
//  CourseContentView.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 18/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class CourseContentView: UIView {

    let fontStyle = OEXTextStyle(font: OEXTextFont.ThemeSans, size: 15.0)
    let smallerFontStyle = OEXTextStyle(font: OEXTextFont.ThemeSans, size: 13.0)
    var titleLabel = UILabel()
    var leftImageButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
    var rightImageButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
    var subtitleLabel = UILabel()
    
    func setProperties(title : String, subtitle : String, leftImageIcon : Icon, rightImageIcon : Icon){
        
        fontStyle.applyToLabel(titleLabel)
        titleLabel.text = title ?? ""
        
        smallerFontStyle.applyToLabel(subtitleLabel)
        subtitleLabel.text = subtitle ?? ""
        
        leftImageButton.titleLabel?.font = Icon.fontWithSize(15)
        leftImageButton.titleLabel?.text = leftImageIcon.textRepresentation
        
        rightImageButton.titleLabel?.font = Icon.fontWithSize(13)
        rightImageButton.titleLabel?.text = rightImageIcon.textRepresentation
        
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setConstraints()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setLeftIconColor(color : UIColor!)
    {
        leftImageButton.titleLabel?.textColor = color
    }
    
    func setRightIconColor(color : UIColor)
    {
        rightImageButton.titleLabel?.textColor = color ?? UIColor.whiteColor()
    }

    func setTitleText(title : String)
    {
        titleLabel.text = title
    }
    
    func setConstraints()
    {
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
    
    func addSubviews()
    {
        addSubview(leftImageButton)
        addSubview(rightImageButton)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
    }
    
    
    
    
}
