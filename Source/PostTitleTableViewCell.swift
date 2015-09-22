//
//  PostTitleTableViewCell.swift
//  edX
//
//  Created by Tang, Jeff on 5/13/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class PostTitleTableViewCell: UITableViewCell {
    
    private let typeButton = UIButton(type: .System)
    private let titleLabel = UILabel()
    private let countButton = UIButton(type: .System)
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(typeButton)
        typeButton.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self.contentView).offset(7)
            make.centerY.equalTo(self.contentView).offset(0)
            make.width.equalTo(25)
            make.height.equalTo(25)
        }
        
        contentView.addSubview(titleLabel)
        titleLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(typeButton.snp_right).offset(8)
            make.centerY.equalTo(contentView).offset(0)
            make.height.equalTo(20)
            make.width.equalTo(200)
        }
        
        contentView.addSubview(countButton)
        countButton.setTitleColor(OEXStyles.sharedStyles().primaryBaseColor(), forState: .Normal)
        countButton.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(contentView).offset(-9)
            make.centerY.equalTo(contentView).offset(0)
            make.width.equalTo(30)
            make.height.equalTo(30)
        }
    }
    
    private var titleTextStyle : OEXTextStyle {
        return OEXTextStyle(weight : .Normal, size: .Small, color : OEXStyles.sharedStyles().neutralDark())
    }
    
    private var countStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Small, color : OEXStyles.sharedStyles().primaryBaseColor())
    }
    
    var titleText : String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.attributedText = titleTextStyle.attributedStringWithText(newValue)
        }
    }
    
    var typeText : NSAttributedString? {
        get {
            return typeButton.attributedTitleForState(.Normal)
        }
        set {
            typeButton.setAttributedTitle(newValue, forState: .Normal)
        }
    }
    
    var postCount : Int {
        get {
            return ((countButton.attributedTitleForState(.Normal)?.string ?? "") as NSString).integerValue
        }
        set {
            let string = countStyle.attributedStringWithText(String(newValue))
            countButton.setAttributedTitle(string, forState: .Normal)
        }
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}