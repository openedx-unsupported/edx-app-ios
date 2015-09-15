//
//  DiscussionTopicsCell.swift
//  edX
//
//  Created by Jianfeng Qiu on 11/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class DiscussionTopicsCell: UITableViewCell {

    static let identifier = "DiscussionTopicsCellIdentifier"
    
    private let titleLabel = UILabel()
    
    private var titleTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Base, color : OEXStyles.sharedStyles().neutralBlack())
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        configureViews()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var margin : CGFloat {
        return OEXStyles.sharedStyles().standardHorizontalMargin()
    }
    
    var topic : DiscussionTopic? = nil {
        didSet {
            let titleStyle : OEXTextStyle
            let depth = topic?.depth ?? 0
            self.depth = depth
            
            var titleAttributedStrings = [NSAttributedString]()
            if let topicIcon = topic?.icon {
                titleAttributedStrings.append(topicIcon.attributedTextWithStyle(titleTextStyle, inline: true))
            }
            if let discussionTopic = topic {
                titleAttributedStrings.append(titleTextStyle.attributedStringWithText(discussionTopic.name))
            }
            
            self.titleLabel.attributedText = NSAttributedString.joinInNaturalLayout(titleAttributedStrings)
        }
    }
    
    private var indent : CGFloat {
        return self.margin * CGFloat((self.depth + 1))
    }
    
    func configureViews() {
        applyStandardSeparatorInsets()
        
        self.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        self.contentView.addSubview(titleLabel)

        self.titleLabel.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(self.contentView).offset(margin)
            make.top.equalTo(self.contentView)
            make.bottom.equalTo(self.contentView)
            make.leading.equalTo(self.contentView).offset(indent)
        }
    }
    
    private var depth : UInt = 0 {
        didSet {
            self.titleLabel.snp_updateConstraints { make in
                make.leading.equalTo(self.contentView).offset(self.indent)
            }
        }
    }

}
