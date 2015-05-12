//
//  OEXCourseDashboardCell.swift
//  edX
//
//  Created by Qiu, Jianfeng on 5/8/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class OEXCourseDashboardCell: UITableViewCell {
    
    static let identifier = "CourseDashboardCellIdentifier"
    
    static let titleTextColor = UIColor.blackColor()
    static let titleTextFont = UIFont(name: "HelveticaNeue", size: CGFloat(14))
    static let detailTextColor = UIColor(red: 100/255.0, green: 100/255.0, blue: 100/255.0, alpha: 1.0)
    static let detailTextFont = UIFont(name: "HelveticaNeue", size: CGFloat(11))

    var container = UIView()
    var iconImageView = UIImageView()
    var titleLabel = UILabel()
    var detailLabel = UILabel()
    var indicatorImageView = UIImageView()
    var bottomLine = UIView()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        configureViews()
        
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureViews() {
        self.bottomLine.backgroundColor = UIColor(red: 224.0/255.0, green: 224.0/255.0, blue: 224.0/255.0, alpha: 1.0)
        
        self.titleLabel.textColor = OEXCourseDashboardCell.titleTextColor
        self.titleLabel.font = OEXCourseDashboardCell.titleTextFont
        self.detailLabel.textColor = OEXCourseDashboardCell.detailTextColor
        self.detailLabel.font = OEXCourseDashboardCell.detailTextFont
        
        self.container.addSubview(iconImageView)
        self.container.addSubview(titleLabel)
        self.container.addSubview(detailLabel)
        self.container.addSubview(indicatorImageView)
        
        self.contentView.addSubview(container)
        self.contentView.addSubview(bottomLine)
        
        self.container.snp_makeConstraints { make -> Void in
            make.left.equalTo(self.contentView).offset(0)
            make.right.equalTo(self.contentView).offset(0)
            make.top.equalTo(self.contentView).offset(0)
            make.bottom.equalTo(self.contentView).offset(-1)
        }
        self.bottomLine.snp_makeConstraints { (make) -> Void in
            make.left.equalTo(self.contentView).offset(0)
            make.right.equalTo(self.contentView).offset(0)
            make.bottom.equalTo(self.contentView).offset(0)
            make.height.equalTo(1)
        }
        self.iconImageView.snp_makeConstraints { (make) -> Void in
            make.left.equalTo(self.container).offset(15)
            make.centerY.equalTo(self.container).offset(0)
            make.width.equalTo(30)
            make.height.equalTo(30)
        }
        self.indicatorImageView.snp_makeConstraints { (make) -> Void in
            make.right.equalTo(self.container).offset(-15)
            make.centerY.equalTo(self.container).offset(0)
            make.width.equalTo(10)
            make.height.equalTo(20)
        }
        self.titleLabel.snp_makeConstraints { (make) -> Void in
            make.left.equalTo(self.iconImageView.snp_right).offset(10)
            make.right.equalTo(self.indicatorImageView.snp_left).offset(0)
            make.top.equalTo(self.container).offset(20)
            make.height.equalTo(20)
        }
        self.detailLabel.snp_makeConstraints { (make) -> Void in
            make.left.equalTo(self.titleLabel).offset(0)
            make.right.equalTo(self.titleLabel).offset(0)
            make.top.equalTo(self.titleLabel.snp_bottom).offset(0)
            make.height.equalTo(20)
        }
        
        
        
    }

}
