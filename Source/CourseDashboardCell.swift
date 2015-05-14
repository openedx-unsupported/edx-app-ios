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
    let ICON_SIZE_WIDTH = 30.0
    let ICON_MARGIN_LEFT = 15.0
    let LABEL_SIZE_HEIGHT = 20.0
    let CONTAINER_SIZE_HEIGHT = 60.0
    let CONTAINER_MARGIN_BOTTOM = 15.0
    let TEXT_MARGIN = 10.0
    let SEPARATORLINE_SIZE_HEIGHT = 1.0
    let INDICATOR_SIZE_WIDTH = 10.0
    
    var container = UIView()
    var iconImageView = UIImageView()
    var titleLabel = UILabel()
    var detailLabel = UILabel()
    var indicatorImageView = UIImageView()
    var bottomLine = UIView()
    
    var titleTextStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(font: .ThemeSans, size: 14.0)
        style.color = OEXStyles.sharedStyles()?.neutralBlack()
        return style
    }
    var detailTextStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(font: .ThemeSans, size: 11.0)
        style.color = OEXStyles.sharedStyles()?.neutralDark()
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
        self.bottomLine.backgroundColor = OEXStyles.sharedStyles()?.neutralXXLight()
        
        titleTextStyle.applyToLabel(self.titleLabel)
        detailTextStyle.applyToLabel(self.detailLabel)
        
        self.container.addSubview(iconImageView)
        self.container.addSubview(titleLabel)
        self.container.addSubview(detailLabel)
        self.container.addSubview(indicatorImageView)
        
        self.contentView.addSubview(container)
        self.contentView.addSubview(bottomLine)
        
        self.bottomLine.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self.contentView)
            make.trailing.equalTo(self.contentView)
            make.bottom.equalTo(self.contentView)
            make.height.equalTo(SEPARATORLINE_SIZE_HEIGHT)
        }
        self.container.snp_makeConstraints { make -> Void in
            make.leading.equalTo(self.contentView)
            make.trailing.equalTo(self.contentView)
            make.top.equalTo(self.contentView)
            make.bottom.equalTo(self.bottomLine.snp_top)
        }
        self.iconImageView.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self.container).offset(ICON_MARGIN_LEFT)
            make.centerY.equalTo(self.container)
            make.width.equalTo(ICON_SIZE_WIDTH)
            make.height.equalTo(ICON_SIZE_WIDTH)
        }
        self.indicatorImageView.snp_makeConstraints { (make) -> Void in
            make.trailing.equalTo(self.container).offset(-ICON_MARGIN_LEFT)
            make.centerY.equalTo(self.container)
            make.width.equalTo(INDICATOR_SIZE_WIDTH)
            make.height.equalTo(LABEL_SIZE_HEIGHT)
        }
        self.titleLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self.iconImageView.snp_right).offset(TEXT_MARGIN)
            make.trailing.equalTo(self.indicatorImageView.snp_left)
            make.top.equalTo(self.container).offset(LABEL_SIZE_HEIGHT)
            make.height.equalTo(LABEL_SIZE_HEIGHT)
        }
        self.detailLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(self.titleLabel)
            make.trailing.equalTo(self.titleLabel)
            make.top.equalTo(self.titleLabel.snp_bottom)
            make.height.equalTo(LABEL_SIZE_HEIGHT)
        }
    }

}
