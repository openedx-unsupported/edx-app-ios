//
//  PostTitleByTableViewCell.swift
//  edX
//
//  Created by Tang, Jeff on 5/13/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit


class PostTitleByTableViewCell: UITableViewCell {
    
    private let typeButton = UILabel()
    private let byLabel = UILabel()
    private let titleLabel = UILabel()
    private let countButton = UIButton.buttonWithType(.Custom) as! UIButton
    
    var cellTextStyle : OEXTextStyle {
        return OEXTextStyle(weight : .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralLight())
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        self.postRead = false
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(typeButton)
        contentView.addSubview(titleLabel)
        contentView.addSubview(byLabel)
        contentView.addSubview(countButton)
        
        typeButton.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self.contentView).offset(15)
            make.centerY.equalTo(self.contentView)
            make.size.equalTo(typeButton.intrinsicContentSize())
        }
        
        titleLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(typeButton.snp_trailing).offset(15)
            make.centerY.equalTo(self.contentView).offset(-5)
            make.height.equalTo(20)
            make.trailing.equalTo(countButton.snp_leading).offset(-8)
        }
        
        byLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp_bottom)
            make.trailing.equalTo(titleLabel)
        }
        
        countButton.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(self.contentView).offset(-10)
            make.centerY.equalTo(self.contentView).offset(0)
            make.size.equalTo(self.countButton.intrinsicContentSize())
        }
        
    
    }
    
    override func updateConstraints() {
        super.updateConstraints()
        
        typeButton.snp_updateConstraints { (make) -> Void in
            make.size.equalTo(typeButton.intrinsicContentSize())
        }
        
        countButton.snp_updateConstraints { (make) -> Void in
            make.size.equalTo(countButton.intrinsicContentSize())
        }
        
    }
    
    private var titleTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Small, color : OEXStyles.sharedStyles().neutralXDark())
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
            return typeButton.attributedText
        }
        set {
            typeButton.attributedText = newValue
        }
    }
    
    var byText : NSAttributedString? {
        get {
            return byLabel.attributedText
        }
        set {
            byLabel.attributedText = newValue
        }
    }
    
    var postCount : Int {
        get {
            return ((countButton.attributedTitleForState(.Normal)?.string ?? "") as NSString).integerValue
        }
        set {
            let countString = countStyle.attributedStringWithText(String(newValue))
            let buttonTitleString = NSAttributedString.joinInNaturalLayout(before: countString, after: Icon.Comment.attributedTextWithStyle(countStyle))
            
            countButton.setAttributedTitle(buttonTitleString, forState: .Normal)
        }
    }
    
    var postRead : Bool {
        didSet {
            self.contentView.backgroundColor = postRead ? OEXStyles.sharedStyles().neutralXXLight() : OEXStyles.sharedStyles().neutralWhiteT()
        }
    }


    func usePost(post : DiscussionPostItem) {
        self.typeText = iconForType(post.type).attributedTextWithStyle(cellTextStyle)
        self.titleText = post.title
        self.byText = styledCellTextWithIcon(.User, text: post.author)
        self.postCount = post.count
        self.postRead = post.read
        self.setNeedsUpdateConstraints()
    }
    
    func styledCellTextWithIcon(icon : Icon, text : String?) -> NSAttributedString? {
        let style = cellTextStyle.withSize(.XSmall).withColor(OEXStyles.sharedStyles().neutralBase())
        return text.map {text in
            return NSAttributedString.joinInNaturalLayout(
                before: icon.attributedTextWithStyle(style),
                after: style.attributedStringWithText(text))
        }
    }
    
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func iconForType(type : PostThreadType) -> Icon {
        switch type {
        case .Discussion:
            return Icon.Comments
        case .Question:
            return Icon.Question
        }
    }
    
}
