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

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        self.backgroundColor =  OEXStyles.sharedStyles().neutralXLight()

        applyStandardSeparatorInsets()

        contentView.addSubview(certificateImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(getButton)

        certificateImageView.backgroundColor = UIColor.redColor()
        certificateImageView.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Horizontal)

        getButton.backgroundColor = UIColor.greenColor()

        titleLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, forAxis: .Horizontal)

        certificateImageView.snp_makeConstraints(closure: { (make) -> Void in
            make.centerY.equalTo(contentView)
            make.leading.equalTo(contentView.snp_leading).offset(15)
        })

        titleLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(certificateImageView)
            make.leading.equalTo(certificateImageView.snp_trailing).offset(14)
            make.trailing.equalTo(contentView.snp_trailingMargin)
        }

        subtitleLabel.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp_bottom)
        }

        getButton.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(titleLabel)
            make.bottom.equalTo(certificateImageView)
        }
    }
}