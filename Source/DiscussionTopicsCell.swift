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
    
    // TODO: adjust each value once the final UI is out
    private let ICON_SIZE_WIDTH = 20.0
    private let LABEL_SIZE_HEIGHT = 20.0
    private let SEPARATORLINE_SIZE_HEIGHT = 1.0
    private let ICON_MARGIN_LEFT = 15.0
    
    private let titleLabel = UILabel()
    private let separatorLine = UIView()
    
    private var titleTextStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Normal, size: .XSmall, color : OEXStyles.sharedStyles().neutralBlack())
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
            self.titleLabel.attributedText = titleTextStyle.attributedStringWithText(topic?.name)
            self.depth = topic?.depth ?? 0
        }
    }
    
    private var indent : CGFloat {
        return self.margin * CGFloat((self.depth + 1))
    }
    
    func configureViews() {
        self.separatorLine.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        
        self.contentView.addSubview(titleLabel)
        self.contentView.addSubview(separatorLine)
        
        self.separatorLine.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self.contentView)
            make.trailing.equalTo(self.contentView)
            make.top.equalTo(self.contentView)
            make.height.equalTo(SEPARATORLINE_SIZE_HEIGHT)
        }
        self.titleLabel.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(self.contentView).offset(margin)
            make.centerY.equalTo(self.contentView)
            make.height.equalTo(LABEL_SIZE_HEIGHT)
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
