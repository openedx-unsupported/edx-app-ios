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
    let ICON_SIZE_WIDTH = 20.0
    let LABEL_SIZE_HEIGHT = 20.0
    let SEPARATORLINE_SIZE_HEIGHT = 1.0
    let TEXT_MARGIN = 10.0
    let ICON_MARGIN_LEFT = 15.0
    
    var container = UIView()
    var iconImageView = UIImageView()
    var titleLabel = UILabel()
    var separatorLine = UIView()
    
    var titleTextStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(font: .ThemeSans, size: 12.0)
        style.color = OEXStyles.sharedStyles()?.neutralBlack()
        return style
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        configureViews()
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureViews() {
        self.separatorLine.backgroundColor = OEXStyles.sharedStyles()?.neutralXXLight()
        
        titleTextStyle.applyToLabel(self.titleLabel)
        
        self.container.addSubview(iconImageView)
        self.container.addSubview(titleLabel)
        
        self.contentView.addSubview(container)
        self.contentView.addSubview(separatorLine)
        
        self.separatorLine.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self.contentView)
            make.trailing.equalTo(self.contentView)
            make.top.equalTo(self.contentView)
            make.height.equalTo(SEPARATORLINE_SIZE_HEIGHT)
        }
        
        self.container.snp_makeConstraints { make -> Void in
            make.leading.equalTo(self.contentView)
            make.trailing.equalTo(self.contentView)
            make.top.equalTo(self.separatorLine.snp_bottom)
            make.bottom.equalTo(self.contentView)
        }
        
        self.iconImageView.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self.container).offset(ICON_MARGIN_LEFT)
            make.centerY.equalTo(self.container)
            make.width.equalTo(ICON_SIZE_WIDTH)
            make.height.equalTo(ICON_SIZE_WIDTH)
        }
        self.titleLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self.iconImageView.snp_right).offset(TEXT_MARGIN)
            make.trailing.equalTo(self.contentView).offset(-TEXT_MARGIN)
            make.centerY.equalTo(self.container)
            make.height.equalTo(LABEL_SIZE_HEIGHT)
        }
    }

}
