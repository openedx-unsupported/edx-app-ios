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
    private let DISCLOSURE_MARGIN_TRAILING = -10.0
    private let DISCLOSURE_SIZE = CGSizeMake(18, 18)
    
    private let container = UIView()
    private let iconView = UILabel()
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let bottomLine = UIView()
    private let mockDisclosureLabel = UILabel()
    
    
    private var titleTextStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(font: .ThemeSans, size: 14.0)
        style.color = OEXStyles.sharedStyles().neutralBlack()
        return style
    }
    private var detailTextStyle : OEXTextStyle {
        let style = OEXMutableTextStyle(font: .ThemeSans, size: 11.0)
        style.color = OEXStyles.sharedStyles().neutralDark()
        return style
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        configureViews()
    }
    
    func useItem(item : CourseDashboardItem) {
            self.titleLabel.text = item.title
            self.detailLabel.text = item.detail
            self.iconView.text = item.icon.textRepresentation
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureViews() {
        self.bottomLine.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        
        titleTextStyle.applyToLabel(self.titleLabel)
        detailTextStyle.applyToLabel(self.detailLabel)
        
        self.separatorInset = UIEdgeInsetsMake(0, ICON_MARGIN, 0, 0)
        
        self.container.addSubview(iconView)
        self.container.addSubview(titleLabel)
        self.container.addSubview(detailLabel)
        self.container.addSubview(mockDisclosureLabel)
        
        self.contentView.addSubview(container)
        
        self.mockDisclosureLabel.font = Icon.fontWithSize(18)
        
        if (isRTL) {
            self.mockDisclosureLabel.text = Icon.DisclosureRTL.textRepresentation
        }
        else {
            self.mockDisclosureLabel.text = Icon.DisclosureLTR.textRepresentation
        }
        
        
        self.mockDisclosureLabel.textColor = OEXStyles.sharedStyles().neutralLight()
        
        iconView.font = Icon.fontWithSize(ICON_SIZE)
        iconView.textColor = OEXStyles.sharedStyles().neutralLight()
        
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
        
        mockDisclosureLabel.snp_makeConstraints { (make) -> Void in
            make.centerY.equalTo(container)
            make.trailing.equalTo(container.snp_trailing).offset(DISCLOSURE_MARGIN_TRAILING)
            make.size.equalTo(DISCLOSURE_SIZE)
        }
    }

    private var isRTL : Bool {
        return UIApplication.sharedApplication().userInterfaceLayoutDirection == UIUserInterfaceLayoutDirection.RightToLeft
    }
}
