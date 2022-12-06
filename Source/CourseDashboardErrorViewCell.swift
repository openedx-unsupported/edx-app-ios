//
//  CourseDashboardErrorViewCell.swift
//  edX
//
//  Created by Saeed Bashir on 11/29/22.
//  Copyright © 2022 edX. All rights reserved.
//

import Foundation

class CourseDashboardErrorViewCell: UITableViewCell {
    static let identifier = "CourseDashboardErrorView"

    var gotoMyCoursesAction: (() -> Void)?

    private let containerView = UIView()
    private let bottomContainer = UIView()
    private let errorLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "CourseDashboardErrorViewCell:error-label"
        label.numberOfLines = 0
        let style = OEXMutableTextStyle(weight: .bold, size: .xxLarge, color: OEXStyles.shared().neutralBlackT())
        style.alignment = .center
        label.attributedText = style.attributedString(withText: Strings.CourseDashboard.Error.generalError)

        return label
    }()

    private lazy var errorImageView: UIImageView = {
        guard let image = UIImage(named: "dashboard_error_image") else { return UIImageView() }
        let imageView = UIImageView(image: image)
        imageView.accessibilityIdentifier = "CourseDashboardErrorViewCell:error-imageView"
        return imageView
    }()

    private lazy var gotoMyCoursesButton: UIButton = {
        let button = UIButton(type: .system)
        button.accessibilityIdentifier = "CourseDashboardErrorViewCell:gotocourses-button"
        button.backgroundColor = OEXStyles.shared().secondaryBaseColor()
        button.oex_addAction({ [weak self] _ in
            self?.gotoMyCoursesAction?()
        }, for: .touchUpInside)

        let style = OEXTextStyle(weight: .normal, size: .xLarge, color: OEXStyles.shared().neutralWhite())
        button.setAttributedTitle(style.attributedString(withText: Strings.CourseDashboard.Error.goToCourses), for: UIControl.State())

        return button
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none

        addSubViews()
        setAccessibilityIdentifiers()
        setConstraints()
    }

    override func prepareForReuse() {
        setConstraints()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        containerView.addShadow(offset: CGSize(width: 0, height: 2), color: OEXStyles.shared().primaryDarkColor(), radius: 2, opacity: 0.35, cornerRadius: 6)
        setConstraints()
    }


    private func setConstraints() {
        if traitCollection.verticalSizeClass == .regular {
            addPortraitConstraints()
        } else {
            addLandscapeConstraints()
        }
    }

    private func addSubViews() {
        backgroundColor = OEXStyles.shared().neutralWhiteT()

        contentView.addSubview(containerView)

        containerView.addSubview(errorImageView)
        containerView.addSubview(bottomContainer)

        bottomContainer.addSubview(errorLabel)
        bottomContainer.addSubview(gotoMyCoursesButton)

        containerView.backgroundColor = OEXStyles.shared().neutralWhiteT()
    }

    private func setAccessibilityIdentifiers() {
        accessibilityIdentifier = "CourseDashboardErrorViewCell:view"

        containerView.accessibilityIdentifier = "CourseDashboardErrorViewCell:container-view"
        bottomContainer.accessibilityIdentifier = "CourseDashboardErrorViewCell:bottom-container-view"
    }

    private func addPortraitConstraints() {
        containerView.snp.remakeConstraints { make in
            make.top.equalTo(contentView).offset(StandardVerticalMargin * 2)
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
            make.bottom.equalTo(contentView).inset(StandardVerticalMargin * 2)
        }

        errorImageView.snp.remakeConstraints { make in
            make.top.equalTo(containerView)
            make.leading.equalTo(containerView)
            make.trailing.equalTo(containerView)
            make.height.equalTo(StandardVerticalMargin * 33)
        }

        bottomContainer.snp.remakeConstraints { make in
            make.top.equalTo(errorImageView.snp.bottom)
            make.leading.equalTo(containerView)
            make.trailing.equalTo(containerView)
            make.bottom.equalTo(containerView)
        }

        errorLabel.snp.remakeConstraints { make in
            make.top.equalTo(bottomContainer).offset(StandardVerticalMargin * 2)
            make.leading.equalTo(bottomContainer).offset(StandardHorizontalMargin * 2.2)
            make.trailing.equalTo(bottomContainer).inset(StandardHorizontalMargin * 2.2)
        }

        gotoMyCoursesButton.snp.remakeConstraints { make in
            make.top.equalTo(errorLabel.snp.bottom).offset(StandardVerticalMargin * 2)
            make.height.equalTo(StandardVerticalMargin * 5.5)
            make.leading.equalTo(bottomContainer).offset(StandardHorizontalMargin * 2)
            make.trailing.equalTo(bottomContainer).inset(StandardHorizontalMargin * 2)
            make.bottom.equalTo(bottomContainer).inset(StandardVerticalMargin * 2)
        }
    }

    private func addLandscapeConstraints() {
        containerView.snp.remakeConstraints { make in
            make.top.equalTo(contentView).offset(StandardVerticalMargin * 2)
            make.bottom.equalTo(contentView).inset(StandardVerticalMargin * 2)
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
        }

        errorImageView.snp.remakeConstraints { make in
            make.top.equalTo(containerView)
            make.leading.equalTo(containerView)
            make.height.equalTo(StandardVerticalMargin * 33)
            make.width.equalTo(contentView.frame.width / 2)
            make.bottom.equalTo(containerView)
        }

        bottomContainer.snp.remakeConstraints { make in
            make.top.equalTo(containerView).offset(-StandardVerticalMargin * 2)
            make.leading.equalTo(errorImageView.snp.trailing)
            make.trailing.equalTo(containerView)
            make.bottom.equalTo(containerView)
        }

        errorLabel.snp.remakeConstraints { make in
            make.top.equalTo(bottomContainer).offset(StandardVerticalMargin * 2)
            make.leading.equalTo(bottomContainer).offset(StandardHorizontalMargin * 2)
            make.trailing.equalTo(bottomContainer).inset(StandardHorizontalMargin * 2)
            make.bottom.equalTo(gotoMyCoursesButton.snp.top)
        }

        gotoMyCoursesButton.snp.remakeConstraints { make in
            make.bottom.equalTo(bottomContainer).inset(StandardVerticalMargin * 4)
            make.leading.equalTo(bottomContainer).offset(StandardHorizontalMargin * 2)
            make.trailing.equalTo(bottomContainer).inset(StandardHorizontalMargin * 2)
            make.height.equalTo(StandardVerticalMargin * 5.5)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
