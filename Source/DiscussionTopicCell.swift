//
//  DiscussionTopicCell.swift
//  edX
//
//  Created by Jianfeng Qiu on 11/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class DiscussionTopicCell: UITableViewCell {

    static let identifier = "DiscussionTopicCellIdentifier"
    
    private let titleLabel = UILabel()
    
    private var titleTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .Base, color : OEXStyles.sharedStyles().neutralXDark())
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    var topic : DiscussionTopic? = nil {
        didSet {
            let depth = topic?.depth ?? 0
            self.depth = depth
            
            var titleAttributedStrings = [NSAttributedString]()
            if let topicIcon = topic?.icon {
                titleAttributedStrings.append(topicIcon.attributedTextWithStyle(titleTextStyle, inline: true))
            }
            if let discussionTopic = topic {
                titleAttributedStrings.append(titleTextStyle.attributedStringWithText(discussionTopic.name?.userFacingString))
            }
            
            self.titleLabel.attributedText = NSAttributedString.joinInNaturalLayout(titleAttributedStrings)
        }
    }
    
    func configureViews() {
        applyStandardSeparatorInsets()
        
        self.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        self.contentView.addSubview(titleLabel)

        self.titleLabel.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(self.contentView).offset(-StandardHorizontalMargin)
            make.top.equalTo(self.contentView).offset(StandardVerticalMargin)
            make.bottom.equalTo(self.contentView).offset(-StandardVerticalMargin)
            make.leading.equalTo(self.contentView).offset(self.indentationOffsetForDepth(itemDepth: depth))
        }
        self.titleLabel.numberOfLines = 0
    }
    
    private var depth : UInt = 0 {
        didSet {
            self.titleLabel.snp_updateConstraints { make in
                make.leading.equalTo(self.contentView).offset(self.indentationOffsetForDepth(itemDepth: depth))
                self.applyStandardSeparatorInsets()
            }
        }
    }

}

private extension String {
    var userFacingString : String {
        return self.isEmpty ? Strings.untitled : self
    }
}

extension UITableViewCell {
    
    private func indentationOffsetForDepth(itemDepth depth : UInt) -> CGFloat {
        return CGFloat(depth + 1) * StandardHorizontalMargin
    }
}
