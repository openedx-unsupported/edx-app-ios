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

        certificateImageView.contentMode = .ScaleAspectFit
        certificateImageView.setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Horizontal)

        getButton.backgroundColor = UIColor.greenColor()

        titleLabel.setContentCompressionResistancePriority(UILayoutPriorityDefaultLow, forAxis: .Horizontal)
        subtitleLabel.adjustsFontSizeToFitWidth = true

        certificateImageView.snp_makeConstraints(closure: { (make) -> Void in
            make.top.equalTo(contentView).offset(15)
            make.bottom.equalTo(contentView).inset(15)
            make.leading.equalTo(contentView.snp_leading).offset(10)
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

    func useItem(item: CertificateDashboardItem) {
        certificateImageView.image = item.certificateImage

        let titleStyle = OEXTextStyle(weight: .Normal, size: .Large, color: OEXStyles.sharedStyles().primaryXDarkColor())
        let subtitleStyle = OEXTextStyle(weight: .Normal, size: .Base, color: OEXStyles.sharedStyles().neutralDark())

        titleLabel.attributedText = titleStyle.attributedStringWithText(Strings.Certificates.courseCompletionTitle)
        subtitleLabel.attributedText = subtitleStyle.attributedStringWithText(Strings.Certificates.courseCompletionSubtitle)
        getButton.applyButtonStyle(OEXStyles.sharedStyles().filledPrimaryButtonStyle, withTitle: Strings.Certificates.getCertificate)

        getButton.oex_addAction({ _ in
            item.action()
            }, forEvents: .TouchUpInside)
    }
}