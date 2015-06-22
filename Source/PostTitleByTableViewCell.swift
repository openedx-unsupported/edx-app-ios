//
//  PostTitleByTableViewCell.swift
//  edX
//
//  Created by Tang, Jeff on 5/13/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit


class PostTitleByTableViewCell: UITableViewCell {
    
    let typeButton = UIButton.buttonWithType(.System) as! UIButton
    let byLabel = UILabel()
    let titleLabel = UILabel()
    let countButton = UIButton.buttonWithType(.System) as! UIButton
    
    var titleTextStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(font: .ThemeSans, size: 14.0)
        style.color = OEXStyles.sharedStyles().neutralDark()
        return style
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(typeButton)
        contentView.addSubview(titleLabel)
        contentView.addSubview(byLabel)
        contentView.addSubview(countButton)
        
        typeButton.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self.contentView).offset(7)
            make.centerY.equalTo(self.contentView).offset(0)
            make.width.equalTo(25)
            make.height.equalTo(25)
        }

        titleTextStyle.applyToLabel(titleLabel)
        titleLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(typeButton.snp_trailing).offset(8)
            make.top.equalTo(self.contentView).offset(10)
            make.height.equalTo(20)
            make.trailing.equalTo(countButton.snp_leading).offset(-8)
        }
        
        byLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp_bottom).offset(12)
            make.trailing.equalTo(titleLabel)
        }
        
        countButton.setTitleColor(OEXStyles.sharedStyles().primaryBaseColor(), forState: .Normal)
        countButton.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(self.contentView).offset(-9)
            make.centerY.equalTo(self.contentView).offset(0)
            make.width.equalTo(30)
            make.height.equalTo(30)
        }
    }
    

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
