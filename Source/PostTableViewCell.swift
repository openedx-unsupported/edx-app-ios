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
        return OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().neutralXDark())
    }
    
    private var postUnreadStyle : OEXTextStyle {
        return OEXTextStyle(weight: .bold, size: .base, color: OEXStyles.shared().neutralXDark())
    }
    
    private var questionStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().secondaryDarkColor())
    }
    
    private var answerStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().utilitySuccessDark())
    }
    
    private var infoTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .xSmall, color: OEXStyles.shared().neutralDark())
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = OEXStyles.shared().neutralWhite()
        
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
        return OEXTextStyle(weight: .normal, size: .base, color : OEXStyles.shared().neutralXDark())
    }
    
    private var activeCountStyle : OEXTextStyle {
        return OEXTextStyle(weight: .bold, size: .base, color : OEXStyles.shared().primaryBaseColor())
    }
    
    private var inactiveCountStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color : OEXStyles.shared().neutralDark())
    }
    
    private var typeText : NSAttributedString? {
        get {
            return typeLabel.attributedText
        }
        set {
            typeLabel.attributedText = newValue
        }
    }

    private func updateThreadCount(count : String) {
        countLabel.attributedText = activeCountStyle.attributedString(withText: count)
    }
    
    func useThread(thread : DiscussionThread, selectedOrderBy : DiscussionPostsSort) {
        self.typeText = threadTypeText(thread: thread)
        
        titleLabel.attributedText = thread.read ? postReadStyle.attributedString(withText: thread.title) : postUnreadStyle.attributedString(withText: thread.title)
        
        var options = [NSAttributedString]()
        
        if thread.closed { options.append(Icon.Closed.attributedTextWithStyle(style: infoTextStyle, inline : true)) }
        if thread.pinned { options.append(Icon.Pinned.attributedTextWithStyle(style: infoTextStyle, inline : true)) }
        if thread.following { options.append(Icon.FollowStar.attributedTextWithStyle(style: infoTextStyle)) }
        if options.count > 0 { options.append(infoTextStyle.attributedString(withText: Strings.pipeSign)) }
        options.append(infoTextStyle.attributedString(withText: Strings.Discussions.repliesCount(count: formatdCommentsCount(count: thread.commentCount))))
        
        if let updatedAt = thread.updatedAt {
            options.append(infoTextStyle.attributedString(withText: Strings.pipeSign))
            options.append(infoTextStyle.attributedString(withText: Strings.Discussions.lastPost(date: updatedAt.displayDate)))
        }
        
        infoLabel.attributedText = NSAttributedString.joinInNaturalLayout(attributedStrings: options)
        
        let count = formatdCommentsCount(count: thread.unreadCommentCount)
        countLabel.attributedText = activeCountStyle.attributedString(withText: count)
        countLabel.isHidden = !NSNumber(value: thread.unreadCommentCount).boolValue
        
        setAccessibility(thread: thread)
    }
    
    private func styledCellTextWithIcon(icon : Icon, text : String?) -> NSAttributedString? {
        return text.map {text in
            let style = infoTextStyle
            return NSAttributedString.joinInNaturalLayout(attributedStrings: [icon.attributedTextWithStyle(style: style),
                style.attributedString(withText: text)])
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
            return (thread.unreadCommentCount > 0) ? Icon.Comments.attributedTextWithStyle(style: activeCountStyle) : Icon.Comments.attributedTextWithStyle(style: inactiveCountStyle)
        case .Question:
            return thread.hasEndorsed ? Icon.Answered.attributedTextWithStyle(style: answerStyle) : Icon.Question.attributedTextWithStyle(style: questionStyle)
        }
    }
    
    private func setAccessibility(thread : DiscussionThread) {
        var accessibilityString = ""
        
        switch thread.type {
        case .Discussion:
            accessibilityString = Strings.discussion
        case .Question:
            thread.hasEndorsed ? (accessibilityString = Strings.answeredQuestion) : (accessibilityString = Strings.question)
        }
        
        accessibilityString = accessibilityString+","+(thread.title ?? "")
        
        if thread.closed {
            accessibilityString = accessibilityString+","+Strings.Accessibility.discussionClosed
        }
        
        if thread.pinned {
            accessibilityString = accessibilityString+","+Strings.Accessibility.discussionPinned
        }
        
        if thread.following {
            accessibilityString = accessibilityString+","+Strings.Accessibility.discussionFollowed
        }
        
        accessibilityString = accessibilityString+","+Strings.Discussions.repliesCount(count: formatdCommentsCount(count: thread.commentCount))
        
        
        if let updatedAt = thread.updatedAt {
            accessibilityString = accessibilityString+","+Strings.Accessibility.discussionLastPostOn(date: updatedAt.displayDate)
        }
        
        if thread.unreadCommentCount > 0 {
            accessibilityString = accessibilityString+","+Strings.Accessibility.discussionUnreadReplies(count: formatdCommentsCount(count: thread.unreadCommentCount));
        }
        
        accessibilityLabel = accessibilityString
        accessibilityHint = Strings.Accessibility.discussionThreadHint
        
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
