//
//  OEXDiscussionTopicsCell.swift
//  edX
//
//  Created by Qiu, Jianfeng on 5/12/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class OEXDiscussionTopicsCell: UITableViewCell {
    
    static let identifier = "DiscussionTopicsCellIdentifier"

    var container = UIView()
    var iconImageView = UIImageView()
    var titleLabel = UILabel()
    var separatorLine = UIView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        configureViews()
        
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureViews() {
        self.separatorLine.backgroundColor = UIColor(red: 224.0/255.0, green: 224.0/255.0, blue: 224.0/255.0, alpha: 1.0)
        
        // TODO: Temp font and color
        self.titleLabel.textColor = UIColor.blackColor()
        self.titleLabel.font = UIFont(name: "HelveticaNeue", size: CGFloat(12))
        
        self.container.addSubview(iconImageView)
        self.container.addSubview(titleLabel)
        
        self.contentView.addSubview(container)
        self.contentView.addSubview(separatorLine)
        
        self.separatorLine.snp_makeConstraints { (make) -> Void in
            make.left.equalTo(self.contentView).offset(0)
            make.right.equalTo(self.contentView).offset(0)
            make.top.equalTo(self.contentView).offset(0)
            make.height.equalTo(1)
        }
        
        self.container.snp_makeConstraints { make -> Void in
            make.left.equalTo(self.contentView).offset(0)
            make.right.equalTo(self.contentView).offset(0)
            make.top.equalTo(self.contentView).offset(1)
            make.bottom.equalTo(self.contentView).offset(0)
        }
        
        self.iconImageView.snp_makeConstraints { (make) -> Void in
            make.left.equalTo(self.container).offset(15)
            make.centerY.equalTo(self.container).offset(0)
            make.width.equalTo(20)
            make.height.equalTo(20)
        }
        self.titleLabel.snp_makeConstraints { (make) -> Void in
            make.left.equalTo(self.iconImageView.snp_right).offset(10)
            make.right.equalTo(self.contentView).offset(-10)
            make.centerY.equalTo(self.container).offset(0)
            make.height.equalTo(20)
        }
        
        
        
    }
}
