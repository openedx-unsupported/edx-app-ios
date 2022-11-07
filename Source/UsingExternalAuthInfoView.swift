//
//  UsingExternalAuthInfoView.swift
//  edX
//
//  Created by Saeed Bashir on 11/3/22.
//  Copyright © 2022 edX. All rights reserved.
//

import Foundation
import UIKit

@objc class UsingExternalAuthInfoView: UIView {
    private let containerView = UIView()
    private let iconSize = 20
    private let topContainerView: UIView = {
        let view = UIView()
        view.addShadow(offset: CGSize(width: 0, height: 2), color: OEXStyles.shared().primaryDarkColor(), radius: 2, opacity: 0.35, cornerRadius: 5)
        view.backgroundColor = OEXStyles.shared().successXXLight()
        return view
    }()

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.accessibilityIdentifier = "UsingExternalAuthInfoView:image-view"
        imageView.image = Icon.CheckCircle.imageWithFontSize(size: 18).image(with: OEXStyles.shared().successBase())
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "UsingExternalAuthInfoView:title-label"
        label.numberOfLines = 0
        label.textAlignment = .left
        return label
    }()

    private let messageLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "UsingExternalAuthInfoView:message-label"
        label.numberOfLines = 0
        label.textAlignment = .left
        let style = OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().neutralXXDark())
        label.attributedText = style.attributedString(withText: Strings.Registration.SocialAuthLinked.message(platformName: OEXConfig.shared().platformName())).setLineHeight(1.42)
        return label
    }()

    private let regInfoLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "UsingExternalAuthInfoView:info-label"
        let style = OEXTextStyle(weight: .bold, size: .base, color: OEXStyles.shared().neutralBlackT())
        label.attributedText = style.attributedString(withText: Strings.Registration.SocialAuthLinked.completeRegistration)
        return label
    }()

    @objc init(frame: CGRect, providerName: String) {
        super.init(frame: frame)
        configure(with: providerName)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configure(with providerName: String) {

        addSubview(containerView)
        containerView.addSubview(topContainerView)
        containerView.addSubview(regInfoLabel)
        topContainerView.addSubview(imageView)
        topContainerView.addSubview(titleLabel)
        topContainerView.addSubview(messageLabel)

        containerView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        topContainerView.snp.makeConstraints { make in
            make.leading.equalTo(containerView).offset(StandardHorizontalMargin / 3.75)
            make.trailing.equalTo(containerView).inset(StandardHorizontalMargin / 3.75)
            make.top.equalTo(containerView)
        }

        imageView.snp.makeConstraints { make in
            make.leading.equalTo(topContainerView).offset(StandardHorizontalMargin * 1.74)
            make.top.equalTo(topContainerView).offset(StandardVerticalMargin * 3.26)
            make.height.equalTo(iconSize)
            make.width.equalTo(iconSize)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(imageView.snp.trailing).offset(StandardHorizontalMargin * 0.77)
            make.trailing.equalTo(topContainerView).inset(StandardHorizontalMargin * 1.6)
            make.top.equalTo(topContainerView).offset(StandardVerticalMargin * 2.5)
        }

        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(StandardVerticalMargin / 2)
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(titleLabel)
            make.bottom.equalTo(topContainerView).inset(StandardVerticalMargin * 3)
        }

        regInfoLabel.snp.makeConstraints { make in
            make.leading.equalTo(topContainerView)
            make.trailing.equalTo(topContainerView)
            make.top.equalTo(topContainerView.snp.bottom).offset(StandardVerticalMargin * 4)
            make.bottom.equalTo(containerView).inset(StandardVerticalMargin)
        }

        let titleStyle = OEXTextStyle(weight: .bold, size: .xLarge, color: OEXStyles.shared().neutralBlackT())

        titleLabel.attributedText = titleStyle.attributedString(withText: Strings.Registration.SocialAuthLinked.title(service: providerName)).setLineHeight(1.1)

        accessibilityIdentifier = "UsingExternalAuthInfoView:view"
    }
}
