//
//  PostTableViewCell.swift
//  edX
//
//  Created by Tang, Jeff on 5/13/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit


class PostTableViewCell: UITableViewCell {
    
    static let identifier = "PostCell"
    
    private let typeButton = UILabel()
    private let byLabel = UILabel()
    private let titleLabel = UILabel()
    private let countButton = UIButton(type: .Custom)
    
    private var postTypeStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralLight())
    }
    
    private var questionStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().secondaryDarkColor())
    }
    
    private var answerStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().utilitySuccessDark())
    }
    
    private var cellDetailTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Small, color: OEXStyles.sharedStyles().neutralBase())
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        self.postRead = false
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        contentView.addSubview(typeButton)
        contentView.addSubview(titleLabel)
        contentView.addSubview(byLabel)
        contentView.addSubview(countButton)
        
        addConstraints()
        
        titleLabel.numberOfLines = 2
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addConstraints() {
        typeButton.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self.contentView).offset(15)
            make.centerY.equalTo(self.contentView)
            //forcing the size because different icons can have different intrinzicContentSizes.
            //that changes the position of the titleLabel
            make.size.equalTo(CGSizeMake(20, 20))
        }
        titleLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(typeButton.snp_trailing).offset(10)
            make.top.greaterThanOrEqualTo(self.contentView).offset(StandardVerticalMargin)
        }
        
        byLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(titleLabel)
            make.top.greaterThanOrEqualTo(titleLabel.snp_bottom)
            make.bottom.equalTo(contentView).offset(-StandardVerticalMargin)
        }
    }
    
    private var titleTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Base, color : OEXStyles.sharedStyles().neutralXDark())
    }
    
    private var activeCountStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Small, color : OEXStyles.sharedStyles().primaryBaseColor())
    }
    
    private var inactiveCountStyle : OEXTextStyle {
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

    private func updateThreadCount(count : Int, selectedOrderBy : DiscussionPostsSort, hasActivity activity: Bool, reverseIconAndCount reverse : Bool ) {
        
        let textStyle = activity ? activeCountStyle : inactiveCountStyle
        let icon = selectedOrderBy.icon.attributedTextWithStyle(textStyle, inline : true)
        let countString = textStyle.attributedStringWithText(String(count))
        var buttonTitleStrings = [countString, icon]
        
        if reverse { buttonTitleStrings = buttonTitleStrings.reverse() }
        
        let buttonTitle = NSAttributedString.joinInNaturalLayout(buttonTitleStrings)
        countButton.setAttributedTitle(buttonTitle, forState: .Normal)
    }
        
    func useThread(thread : DiscussionThread, selectedOrderBy : DiscussionPostsSort) {
        self.typeText = threadTypeText(thread)
        self.titleText = thread.title
        var options = [NSAttributedString]()
        
        if thread.closed {
            options.append(Icon.Closed.attributedTextWithStyle(cellDetailTextStyle, inline : true))
        }
        if thread.pinned {
            options.append(Icon.Pinned.attributedTextWithStyle(cellDetailTextStyle, inline : true))
        }
        
        if thread.following {
            options.append(Icon.FollowStar.attributedTextWithStyle(cellDetailTextStyle))
        }

        if let authorString = thread.authorLabel {
            let authorLabelText = Strings.byAuthor(authorName: authorString)
            options.append(cellDetailTextStyle.attributedStringWithText(authorLabelText))
        }
        
        self.byText = NSAttributedString.joinInNaturalLayout(options)
        
        titleLabel.snp_updateConstraints { (make) -> Void in
            let situationalOffset = options.count > 0 ? -StandardVerticalMargin : 0
            make.centerY.equalTo(contentView).offset(situationalOffset)
        }
        
        let count = countForThread(thread, sortBy: selectedOrderBy)
        let hasActivity = shouldShowActivityForThread(thread, sortBy: selectedOrderBy)
        let shouldReverse = shouldReverseIconAndCountForThread(thread, sortBy: selectedOrderBy)
        
        self.updateThreadCount(count, selectedOrderBy: selectedOrderBy, hasActivity: hasActivity, reverseIconAndCount : shouldReverse)

        self.postRead = thread.read
        
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
            make.trailing.equalTo(self.contentView).offset(-15)
            make.centerY.equalTo(self.contentView).offset(0)
            // Add a little padding to the ideal size since UIKit doesn't seem to calculate an intrinsic size
            // correctly (possible related to text attachments)
            make.width.equalTo(((self.countButton.attributedTitleForState(.Normal)?.size())?.width ?? 0) + 2)
        }
        
        super.updateConstraints()
    }
    
    private func threadTypeText(thread : DiscussionThread) -> NSAttributedString {
        switch thread.type {
        case .Discussion:
            return Icon.Comments.attributedTextWithStyle(postTypeStyle)
        case .Question:
            return thread.hasEndorsed ? Icon.Answered.attributedTextWithStyle(answerStyle) : Icon.Question.attributedTextWithStyle(questionStyle)
        }
    }
    
    private func countForThread(thread : DiscussionThread, sortBy : DiscussionPostsSort) -> Int {
        switch sortBy {
        case .VoteCount:
            return thread.voteCount
        case .RecentActivity, .MostActivity:
            return thread.commentCount
        }
    }
    
    private func shouldShowActivityForThread(thread : DiscussionThread, sortBy : DiscussionPostsSort) -> Bool {
        switch sortBy {
        case .VoteCount:
            return thread.voted
        case .RecentActivity, .MostActivity:
            return thread.unreadCommentCount != 0
        }
    }
    
    private func shouldReverseIconAndCountForThread(thread : DiscussionThread, sortBy : DiscussionPostsSort) -> Bool {
        switch sortBy {
        case .VoteCount:
            return true
        case .RecentActivity, .MostActivity:
            return false
        }
    }
}

extension DiscussionPostsSort {
    var icon : Icon {
        switch self {
        case .RecentActivity, .MostActivity:
            return Icon.Comment
        case .VoteCount:
            return Icon.UpVote
        }
    }
}
