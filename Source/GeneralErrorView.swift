//
//  GeneralErrorView.swift
//  edX
//
//  Created by MuhammadUmer on 05/01/2023.
//  Copyright © 2023 edX. All rights reserved.
//

import Foundation

class GeneralErrorView: UIView {
    
    var tapAction: (() -> ())?
    
    init() {
        super.init(frame: .zero)
        
        addSubViews()
        setAccessibilityIdentifiers()
        setConstraints()
    }

    private let containerView = UIView()
    private let bottomContainer = UIView()
    
    private lazy var errorLabelstyle: OEXMutableTextStyle = {
        let style = OEXMutableTextStyle(weight: .bold, size: .xxLarge, color: OEXStyles.shared().neutralBlackT())
        style.alignment = .center
        return style
    }()
   
    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "GeneralErrorView:error-label"
        label.numberOfLines = 0
        label.attributedText = errorLabelstyle.attributedString(withText: Strings.Dashboard.generalErrorMessage)
        return label
    }()

    private lazy var errorImageView: UIImageView = {
        guard let image = UIImage(named: "dashboard_error_image") else { return UIImageView() }
        let imageView = UIImageView(image: image)
        imageView.accessibilityIdentifier = "GeneralErrorView:error-imageView"
        return imageView
    }()
    
    private let buttonTitleStyle = OEXTextStyle(weight: .normal, size: .xLarge, color: OEXStyles.shared().neutralWhite())

    private lazy var errorActionButton: UIButton = {
        let button = UIButton(type: .system)
        button.accessibilityIdentifier = "GeneralErrorView:error-action-button"
        button.backgroundColor = OEXStyles.shared().secondaryBaseColor()
        button.oex_addAction({ [weak self] _ in
            self?.tapAction?()
        }, for: .touchUpInside)

        button.setAttributedTitle(buttonTitleStyle.attributedString(withText: Strings.Dashboard.tryAgain), for: UIControl.State())

        return button
    }()
    
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

        addSubview(containerView)

        containerView.addSubview(errorImageView)
        containerView.addSubview(bottomContainer)
        bottomContainer.addSubview(errorLabel)
        bottomContainer.addSubview(errorActionButton)
        
        containerView.backgroundColor = OEXStyles.shared().neutralWhiteT()
    }

    private func setAccessibilityIdentifiers() {
        accessibilityIdentifier = "GeneralErrorView:view"
        containerView.accessibilityIdentifier = "GeneralErrorView:container-view"
        bottomContainer.accessibilityIdentifier = "GeneralErrorView:bottom-container-view"
    }

    private func addPortraitConstraints() {
        containerView.snp.remakeConstraints { make in
            make.top.equalTo(self).offset(StandardVerticalMargin * 2)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.trailing.equalTo(self).inset(StandardHorizontalMargin)
            make.bottom.equalTo(self).inset(StandardVerticalMargin * 2)
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

        errorActionButton.snp.remakeConstraints { make in
            make.top.equalTo(errorLabel.snp.bottom).offset(StandardVerticalMargin * 2)
            make.height.equalTo(StandardVerticalMargin * 5.5)
            make.leading.equalTo(bottomContainer).offset(StandardHorizontalMargin * 2)
            make.trailing.equalTo(bottomContainer).inset(StandardHorizontalMargin * 2)
            make.bottom.equalTo(bottomContainer).inset(StandardVerticalMargin * 2)
        }
    }

    private func addLandscapeConstraints() {
        containerView.snp.remakeConstraints { make in
            make.top.equalTo(self).offset(StandardVerticalMargin * 2)
            make.bottom.equalTo(self).inset(StandardVerticalMargin * 2)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.trailing.equalTo(self).inset(StandardHorizontalMargin)
        }

        errorImageView.snp.remakeConstraints { make in
            make.top.equalTo(containerView)
            make.leading.equalTo(containerView)
            make.height.equalTo(StandardVerticalMargin * 33)
            make.width.equalTo(frame.width / 2)
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
            make.bottom.equalTo(errorActionButton.snp.top)
        }

        errorActionButton.snp.remakeConstraints { make in
            make.bottom.equalTo(bottomContainer).inset(StandardVerticalMargin * 4)
            make.leading.equalTo(bottomContainer).offset(StandardHorizontalMargin * 2)
            make.trailing.equalTo(bottomContainer).inset(StandardHorizontalMargin * 2)
            make.height.equalTo(StandardVerticalMargin * 5.5)
        }
    }
    
    func setErrorMessage(message: String? = nil, imageName: String? = nil, buttonTitle: String? = nil) {
        errorLabel.attributedText = errorLabelstyle.attributedString(withText: message ?? Strings.Dashboard.generalErrorMessage)
        
        if let image = UIImage(named: imageName ?? "") {
            errorImageView.image = image
        }
        
        if let buttonTitle = buttonTitle {
            errorActionButton.setAttributedTitle(buttonTitleStyle.attributedString(withText: buttonTitle), for: UIControl.State())
        }
    }
    
    func showOutdatedVersionError() {
        errorLabel.attributedText = errorLabelstyle.attributedString(withText: Strings.VersionUpgrade.outDatedMessage)
        
        if let image = UIImage(named: "app_update_image") {
            errorImageView.image = image
        }
        
        errorActionButton.setAttributedTitle(buttonTitleStyle.attributedString(withText: Strings.Coursedates.calendarShiftPromptUpdateNow), for: UIControl.State())
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
