//
//  CourseCertificateCell.swift
//  edX
//
//  Created by Michael Katz on 11/12/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

class CourseCertificateCell: UITableViewCell {

    static let identifier = "CourseCertificateCellIdentifier"

    let certificateImageView = UIImageView()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let getButton = UIButton()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        configureViews()
    }

//    func useItem(item : StandardCourseDashboardItem) {
//        self.titleLabel.attributedText = titleTextStyle.attributedStringWithText(item.title)
//        self.detailLabel.attributedText = detailTextStyle.attributedStringWithText(item.detail)
//        self.iconView.image = item.icon.imageWithFontSize(ICON_SIZE)
//    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        self.backgroundColor =  OEXStyles.sharedStyles().neutralXLight()

        contentView.addSubview(certificateImageView)
        

//        applyStandardSeparatorInsets()
//
//        self.container.addSubview(iconView)
//        self.container.addSubview(titleLabel)
//        self.container.addSubview(detailLabel)
//
//        self.contentView.addSubview(container)
//
//        self.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
//
//        iconView.tintColor = OEXStyles.sharedStyles().neutralLight()
//
//        container.snp_makeConstraints { make -> Void in
//            make.edges.equalTo(contentView)
//        }
//
//        iconView.snp_makeConstraints { (make) -> Void in
//            make.leading.equalTo(container).offset(ICON_MARGIN)
//            make.centerY.equalTo(container)
//        }
//
//        titleLabel.snp_makeConstraints { (make) -> Void in
//            make.leading.equalTo(container).offset(LABEL_MARGIN)
//            make.trailing.lessThanOrEqualTo(container)
//            make.top.equalTo(container).offset(LABEL_SIZE_HEIGHT)
//            make.height.equalTo(LABEL_SIZE_HEIGHT)
//        }
//        detailLabel.snp_makeConstraints { (make) -> Void in
//            make.leading.equalTo(titleLabel)
//            make.trailing.lessThanOrEqualTo(container)
//            make.top.equalTo(titleLabel.snp_bottom)
//            make.height.equalTo(LABEL_SIZE_HEIGHT)
//        }
    }
}