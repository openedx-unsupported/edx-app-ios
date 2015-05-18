//
//  CourseUnknownTableViewCell.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 14/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class CourseUnknownTableViewCell: UITableViewCell {

    static let identifier = "CourseUnknownTableViewCellIdentifier"
    
    let fontStyle = OEXTextStyle(font: OEXTextFont.ThemeSans, size: 15.0)
    let smallFontStyle = OEXTextStyle(font: OEXTextFont.ThemeSans, size: 10.0)
    var titleLabel = UILabel()
    var subTitleLabel = UILabel()
    var leftImageButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
    var block : CourseBlock? = nil {
        didSet {
            titleLabel.text = block?.name ?? ""
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
                subTitleLabel.text = "Sample Subtitle Text for testing"
        addSubviews()
        setStyle()
        setConstraints()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: Helper Methods
    private func addSubviews() {
        addSubview(titleLabel)
        addSubview(leftImageButton)
        addSubview(subTitleLabel)
    }
    
    func setStyle() {
        fontStyle.applyToLabel(titleLabel)
        smallFontStyle.applyToLabel(subTitleLabel)
        
        leftImageButton.titleLabel?.font = Icon.fontWithSize(17)
        leftImageButton.setTitle(Icon.CourseUnknownContent.textRepresentation, forState: .Normal)
        leftImageButton.setTitleColor(OEXStyles.sharedStyles()?.neutralBase(), forState: .Normal)
    }
    
    func setConstraints() {
        leftImageButton.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self)
            make.leading.equalTo(self).offset(UIConstants.ALIconOffsetLeading)
            make.size.equalTo(UIConstants.ALIconSize)
            
        }
        
        titleLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self).offset(UIConstants.ALTitleOffsetCenterY)
            make.leading.equalTo(leftImageButton).offset(UIConstants.ALTitleOffsetLeading)
            make.trailing.equalTo(self.snp_trailing).offset(10)
        }
        
        subTitleLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self).offset(14)
            make.leading.equalTo(leftImageButton).offset(UIConstants.ALTitleOffsetLeading)
        }
    }

}
