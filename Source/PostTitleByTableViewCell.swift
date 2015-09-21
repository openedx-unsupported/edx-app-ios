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
    private let countButton = UIButton(type: .Custom)
    
    private var cellTextStyle : OEXTextStyle {
        return OEXTextStyle(weight : .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralLight())
    }
    
    private var cellDetailTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .XSmall, color: OEXStyles.sharedStyles().neutralBase())
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        self.postRead = false
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(typeButton)
        contentView.addSubview(titleLabel)
        contentView.addSubview(byLabel)
        contentView.addSubview(countButton)
        
        addConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addConstraints() {
        typeButton.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self.contentView).offset(15)
            make.centerY.equalTo(self.contentView)
        }
        
        titleLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(typeButton.snp_trailing).offset(15)
            make.centerY.equalTo(self.contentView).offset(-5)
            make.height.equalTo(20)
        }
        
        byLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp_bottom)
        }
    }
    
    private var hasByText = false
    
    private var titleTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Small, color : OEXStyles.sharedStyles().neutralXDark())
    }
    
    private var unreadCountStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Small, color : OEXStyles.sharedStyles().primaryBaseColor())
    }
    
    private var readCountStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Small, color : OEXStyles.sharedStyles().neutralBase())
    }
    
    private var titleText : String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.attributedText = titleTextStyle.attributedStringWithText(newValue)
        }
    }
    
    private var typeText : NSAttributedString? {
        get {
            return typeButton.attributedText
        }
        set {
            typeButton.attributedText = newValue
        }
    }
    
    private var byText : NSAttributedString? {
        get {
            return byLabel.attributedText
        }
        set {
            byLabel.attributedText = newValue
        }
    }
    
    private var postRead : Bool {
        didSet {
            self.contentView.backgroundColor = postRead ? OEXStyles.sharedStyles().neutralXXLight() : OEXStyles.sharedStyles().neutralWhiteT()
        }
    }

    private func updatePostCount(count : Int, selectedOrderBy : DiscussionPostsSort, readStatus : Bool) {
        let textStyle = (readStatus || selectedOrderBy == .VoteCount) ? readCountStyle : unreadCountStyle
        let icon = selectedOrderBy.icon.attributedTextWithStyle(textStyle)

        let countString = textStyle.attributedStringWithText(String(count))
        let buttonTitle = NSAttributedString.joinInNaturalLayout([countString, icon])
        countButton.setAttributedTitle(buttonTitle, forState: .Normal)
    }
        
    func usePost(post : DiscussionPostItem, selectedOrderBy : DiscussionPostsSort) {
        self.typeText = iconForPost(post).attributedTextWithStyle(cellTextStyle)
        self.titleText = post.title
        var options = [NSAttributedString]()
        
        if post.closed {
            options.append(Icon.Closed.attributedTextWithStyle(cellDetailTextStyle, inline : true))
        }
        if post.pinned {
            options.append(Icon.Pinned.attributedTextWithStyle(cellDetailTextStyle, inline : true))
        }
        
        if post.following {
            options.append(Icon.FollowStar.attributedTextWithStyle(cellDetailTextStyle))
        }
        
        if let authorString = post.authorLabel?.localizedString {
            let authorLabelText = NSString.oex_stringWithFormat(OEXLocalizedString("BY_AUTHOR", nil), parameters: ["author_name" : authorString])
            options.append(cellDetailTextStyle.attributedStringWithText(authorLabelText))
        }
        
        self.hasByText = post.hasByText
        self.byText = NSAttributedString.joinInNaturalLayout(options)
        
        let count = selectedOrderBy == .VoteCount ? post.voteCount : post.count
        self.updatePostCount(count, selectedOrderBy: selectedOrderBy, readStatus: post.unreadCommentCount == 0)

        self.postRead = post.read
        self.setNeedsLayout()
        self.layoutIfNeeded()
        self.setNeedsUpdateConstraints()
    }
    
    private func styledCellTextWithIcon(icon : Icon, text : String?) -> NSAttributedString? {
        return text.map {text in
            let style = cellDetailTextStyle
            return NSAttributedString.joinInNaturalLayout([icon.attributedTextWithStyle(style),
                style.attributedStringWithText(text)])
        }
    }
    
    override func updateConstraints() {
        countButton.snp_updateConstraints { (make) -> Void in
            make.leading.greaterThanOrEqualTo(titleLabel.snp_trailing).offset(8)
            make.leading.greaterThanOrEqualTo(byLabel.snp_trailing).offset(8)
            make.trailing.equalTo(self.contentView).offset(-10)
            make.centerY.equalTo(self.contentView).offset(0)
            // Add a little padding to the ideal size since UIKit doesn't seem to calculate an intrinsic size
            // correctly (possible related to text attachments)
            make.width.equalTo(((self.countButton.attributedTitleForState(.Normal)?.size())?.width ?? 0) + 2)
        }
        
        titleLabel.snp_updateConstraints { (make) -> Void in
            let situationalOffset = self.hasByText ? -5 : 0
            make.centerY.equalTo(contentView).offset(situationalOffset)
        }
        
        super.updateConstraints()
    }
    
    private func iconForPost(post : DiscussionPostItem) -> Icon {
        switch post.type {
        case .Discussion:
            return Icon.Comments
        case .Question:
            return post.hasEndorsed ? Icon.Answered : Icon.Question
        }
    }
    
}
