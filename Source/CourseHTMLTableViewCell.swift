//
//  CourseHTMLTableViewCell.swift
//  edX
//
//  Created by Ehmad Zubair Chughtai on 14/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class CourseHTMLTableViewCell: UITableViewCell {

    static let identifier = "CourseHTMLTableViewCellIdentifier"
    
    let fontStyle = OEXTextStyle(font: OEXTextFont.ThemeSans, size: 15.0)
    var leftImageButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
    var titleLabel = UILabel()
    var block : CourseBlock? = nil {
        didSet {
            titleLabel.text = block?.name ?? ""
        }
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubviews()
        setStyles()
        setConstraints()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: Helper methods
    private func setStyles()
    {
        fontStyle.applyToLabel(titleLabel)
        leftImageButton.titleLabel?.font = Icon.fontWithSize(13)
        leftImageButton.setTitle(Icon.CourseHTMLContent.textRepresentation, forState: .Normal)
        leftImageButton.setTitleColor(OEXStyles.sharedStyles()?.primaryBaseColor(), forState: .Normal)
    }
    
    private func addSubviews()
    {
        addSubview(leftImageButton)
        addSubview(titleLabel)
    }
    
    private func setConstraints()
    {
        leftImageButton.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self).offset(20)
            make.centerY.equalTo(self)
            make.size.equalTo(UIConstants.ALIconSize)
        }
        
        titleLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(self).offset(UIConstants.ALTitleOffsetCenterY)
            make.leading.equalTo(leftImageButton).offset(UIConstants.ALTitleOffsetLeading)
            make.trailing.equalTo(self.snp_trailing).offset(UIConstants.ALCellOffsetTrailing)
        }
    }
    

    
    

}
