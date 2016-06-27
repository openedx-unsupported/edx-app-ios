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
    
    private let typeLabel = UILabel()
    private let infoLabel = UILabel()
    private let titleLabel = UILabel()
    private let countLabel = UILabel()
    
    private var postReadStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralXDark())
    }
    
    private var postUnreadStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Bold, size: .Base, color: OEXStyles.sharedStyles().neutralXDark())
    }
    
    private var questionStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().secondaryDarkColor())
    }
    
    private var answerStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().utilitySuccessDark())
    }
    
    private var infoTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .XSmall, color: OEXStyles.sharedStyles().neutralBase())
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = OEXStyles.sharedStyles().neutralWhite()
        
        contentView.addSubview(typeLabel)
        contentView.addSubview(titleLabel)
        contentView.addSubview(infoLabel)
        contentView.addSubview(countLabel)
        
        addConstraints()
        
        titleLabel.numberOfLines = 2
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addConstraints() {
        typeLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.top.equalTo(titleLabel)
        }
        
        titleLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(typeLabel.snp_trailing).offset(StandardHorizontalMargin)
            make.top.equalTo(contentView).offset(StandardVerticalMargin)
        }
        
        countLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(titleLabel)
            make.leading.greaterThanOrEqualTo(titleLabel.snp_trailing).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).offset(-StandardHorizontalMargin)
        }
        
        infoLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp_bottom)
            make.bottom.equalTo(contentView).offset(-StandardVerticalMargin)
        }
    }
    
    private var titleTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Base, color : OEXStyles.sharedStyles().neutralXDark())
    }
    
    private var activeCountStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Bold, size: .Base, color : OEXStyles.sharedStyles().primaryBaseColor())
    }
    
    private var inactiveCountStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Base, color : OEXStyles.sharedStyles().neutralBase())
    }
    
    private var typeText : NSAttributedString? {
        get {
            return typeLabel.attributedText
        }
        set {
            typeLabel.attributedText = newValue
        }
    }

    private func updateThreadCount(count : String, selectedOrderBy : DiscussionPostsSort, hasActivity activity: Bool, hidden: Bool ) {
        let textStyle = activity ? activeCountStyle : inactiveCountStyle
        countLabel.attributedText = textStyle.attributedStringWithText(count)
        countLabel.hidden = hidden
    }
    
    func useThread(thread : DiscussionThread, selectedOrderBy : DiscussionPostsSort) {
        self.typeText = threadTypeText(thread)
        
        titleLabel.attributedText = thread.read ? postReadStyle.attributedStringWithText(thread.title) : postUnreadStyle.attributedStringWithText(thread.title)
        
        var options = [NSAttributedString]()
        
        if thread.closed { options.append(Icon.Closed.attributedTextWithStyle(infoTextStyle, inline : true)) }
        if thread.pinned { options.append(Icon.Pinned.attributedTextWithStyle(infoTextStyle, inline : true)) }
        if thread.following { options.append(Icon.FollowStar.attributedTextWithStyle(infoTextStyle)) }
        if options.count > 0 { options.append(infoTextStyle.attributedStringWithText(Strings.pipeSign)) }
        options.append(infoTextStyle.attributedStringWithText(Strings.Discussions.repliesCount(count: formatdCommentsCount(thread.commentCount))))
        
        if let updatedAt = thread.updatedAt {
            options.append(infoTextStyle.attributedStringWithText(Strings.pipeSign))
            options.append(infoTextStyle.attributedStringWithText(Strings.Discussions.lastPost(date: updatedAt.displayDate)))
        }
        
        infoLabel.attributedText = NSAttributedString.joinInNaturalLayout(options)
        
        let count = countForThread(thread, sortBy: selectedOrderBy)
        let hasActivity = shouldShowActivityForThread(thread, sortBy: selectedOrderBy)
        let hidden = shouldHideCountLabel(thread, sortBy: selectedOrderBy)
        updateThreadCount(count, selectedOrderBy: selectedOrderBy, hasActivity: hasActivity, hidden: hidden)
    }
    
    private func styledCellTextWithIcon(icon : Icon, text : String?) -> NSAttributedString? {
        return text.map {text in
            let style = infoTextStyle
            return NSAttributedString.joinInNaturalLayout([icon.attributedTextWithStyle(style),
                style.attributedStringWithText(text)])
        }
    }
    
    private func formatdCommentsCount(count: NSInteger) -> String {
        if count > 99 {
            return "99+"
        }
        
        return String(count)
    }
    
    private func threadTypeText(thread : DiscussionThread) -> NSAttributedString {
        switch thread.type {
        case .Discussion:
            return (thread.unreadCommentCount > 0) ? Icon.Comments.attributedTextWithStyle(activeCountStyle) : Icon.Comments.attributedTextWithStyle(inactiveCountStyle)
        case .Question:
            return thread.hasEndorsed ? Icon.Answered.attributedTextWithStyle(answerStyle) : Icon.Question.attributedTextWithStyle(questionStyle)
        }
    }
    
    private func countForThread(thread : DiscussionThread, sortBy : DiscussionPostsSort) -> String {
        switch sortBy {
        case .VoteCount:
            return formatdCommentsCount(thread.voteCount)
        case .RecentActivity, .MostActivity:
            return formatdCommentsCount(thread.unreadCommentCount)
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
    
    private func shouldHideCountLabel(thread : DiscussionThread, sortBy : DiscussionPostsSort) -> Bool {
        switch sortBy {
        case .VoteCount:
            return false
        case .RecentActivity, .MostActivity:
            return thread.unreadCommentCount == 0
        }
    }
}

extension DiscussionPostsSort {
    var canHide : Bool {
        switch self {
        case .RecentActivity, .MostActivity:
            return true
        case .VoteCount:
            return false
        }
    }
}
