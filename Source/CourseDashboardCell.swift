//
//  CourseDashboardCell.swift
//  edX
//
//  Created by Jianfeng Qiu on 13/05/2015.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class CourseDashboardCell: UITableViewCell {

    static let identifier = "CourseDashboardCellIdentifier"
    
    //TODO: all these should be adjusted once the final UI is ready
    private let ICON_SIZE : CGFloat = 20.0
    private let ICON_MARGIN : CGFloat = 20.0
    private let LABEL_SIZE_HEIGHT = 20.0
    private let CONTAINER_SIZE_HEIGHT = 60.0
    private let CONTAINER_MARGIN_BOTTOM = 15.0
    private let INDICATOR_SIZE_WIDTH = 10.0
    
    private let container = UIView()
    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let bottomLine = UIView()
    
    private var titleTextStyle : OEXTextStyle {
        return OEXTextStyle(weight : .Normal, size: .Small, color : OEXStyles.sharedStyles().neutralBlack())
    }
    private var detailTextStyle : OEXTextStyle {
        return OEXTextStyle(weight : .Normal, size: .XXSmall, color : OEXStyles.sharedStyles().neutralDark())
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        configureViews()
    }
    
    func useItem(item : CourseDashboardItem) {
        self.titleLabel.attributedText = titleTextStyle.attributedStringWithText(item.title)
        self.detailLabel.attributedText = detailTextStyle.attributedStringWithText(item.detail)
        self.iconView.image = item.icon.imageWithFontSize(ICON_SIZE)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureViews() {
        self.bottomLine.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        
        self.separatorInset = UIEdgeInsetsMake(0, ICON_MARGIN, 0, 0)
        
        self.container.addSubview(iconView)
        self.container.addSubview(titleLabel)
        self.container.addSubview(detailLabel)
        
        self.contentView.addSubview(container)
        
        self.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        
        iconView.tintColor = OEXStyles.sharedStyles().neutralLight()
        
        container.snp_makeConstraints { make -> Void in
            make.edges.equalTo(contentView)
        }
        
        iconView.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(container).offset(ICON_MARGIN)
            make.centerY.equalTo(container)
        }
        
        titleLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(iconView.snp_trailing).offset(ICON_MARGIN)
            make.trailing.lessThanOrEqualTo(container)
            make.top.equalTo(container).offset(LABEL_SIZE_HEIGHT)
            make.height.equalTo(LABEL_SIZE_HEIGHT)
        }
        detailLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(titleLabel)
            make.trailing.lessThanOrEqualTo(container)
            make.top.equalTo(titleLabel.snp_bottom)
            make.height.equalTo(LABEL_SIZE_HEIGHT)
        }
    }
}
