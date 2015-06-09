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
    let byButton = UIButton.buttonWithType(.System) as! UIButton
    let titleLabel = UILabel()
    let byLabel = UILabel()
    let countButton = UIButton.buttonWithType(.System) as! UIButton
    
    var titleTextStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(font: .ThemeSans, size: 14.0)
        style.color = OEXStyles.sharedStyles().neutralDark()
        return style
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(typeButton)
        typeButton.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self.contentView).offset(7)
            make.centerY.equalTo(self.contentView).offset(0)
            make.width.equalTo(25)
            make.height.equalTo(25)
        }

        titleTextStyle.applyToLabel(titleLabel)
        contentView.addSubview(titleLabel)
        titleLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(typeButton.snp_trailing).offset(8)
            make.top.equalTo(self.contentView).offset(10)
            make.height.equalTo(20)
            make.width.equalTo(200)
        }
        
        contentView.addSubview(byButton)
        byButton.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp_bottom).offset(12)
            make.width.equalTo(20)
            make.height.equalTo(20)
        }
        
        titleTextStyle.applyToLabel(byLabel)
        byLabel.textColor = OEXStyles.sharedStyles().primaryBaseColor()
        contentView.addSubview(byLabel)
        byLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(byButton.snp_trailing).offset(5)
            make.top.equalTo(titleLabel.snp_bottom).offset(11)
            make.width.equalTo(200)
            make.height.equalTo(20)
        }
        
        contentView.addSubview(countButton)
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
