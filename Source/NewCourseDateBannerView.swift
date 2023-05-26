//
//  NewCourseDateBannerView.swift
//  edX
//
//  Created by SaeedBashir on 4/12/23.
//  Copyright © 2023 edX. All rights reserved.
//

import Foundation
import UIKit

class NewCourseDateBannerView: UIView {
    private var buttonHeight: CGFloat = 32
    private lazy var container = UIView()
    
    private lazy var messageLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 0
        label.accessibilityIdentifier = "NewCourseDateBannerView:message-label"
        return label
    }()
    
    private lazy var bannerHeaderStyle: OEXMutableTextStyle = {
        let style = OEXMutableTextStyle(weight: .bold, size: .small, color: OEXStyles.shared().neutralXXDark())
        style.lineBreakMode = .byWordWrapping
        return style
    }()
    
    private lazy var bannerBodyStyle: OEXMutableTextStyle = {
        let style = OEXMutableTextStyle(weight: .normal, size: .small, color: OEXStyles.shared().neutralXXDark())
        style.lineBreakMode = .byWordWrapping
        return style
    }()
    
    private lazy var buttonStyle: OEXMutableTextStyle = {
        return OEXMutableTextStyle(weight: .semiBold, size: .base, color: OEXStyles.shared().neutralWhiteT())
    }()
    
    private lazy var bannerButton: UIButton = {
        let button = UIButton()
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        button.layer.backgroundColor = OEXStyles.shared().primaryBaseColor().cgColor
        button.layer.borderColor = OEXStyles.shared().primaryBaseColor().cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = 0
        button.oex_removeAllActions()
        button.oex_addAction({ [weak self] _ in
            self?.bannerButtonAction()
            }, for: .touchUpInside)
        button.accessibilityIdentifier = "NewCourseDateBannerView:reset-date-button"
        return button
    }()
    
    private var isButtonTextAvailable: Bool {
        guard let bannerInfo = bannerInfo, let status = bannerInfo.status else { return false }
        return !status.button.isEmpty
    }
    
    var bannerInfo: DatesBannerInfo?
    weak var delegate: CourseShiftDatesDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setupView() {
        configureViews()
        setConstraints()
        populate()
    }
    
    private func configureViews() {
        container.subviews.forEach { $0.removeFromSuperview() }
        container.superview?.removeFromSuperview()
        backgroundColor = OEXStyles.shared().warningXXLight()
        addSubview(container)
        container.addSubview(messageLabel)
        container.accessibilityIdentifier = "CourseResetDateBannerView:container-view"
        
        if isButtonTextAvailable {
            container.addSubview(bannerButton)
        }
    }
    
    private func setConstraints() {
        container.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(container).offset(StandardVerticalMargin)
            make.leading.equalTo(container).offset(StandardHorizontalMargin)
            make.trailing.equalTo(container).inset(StandardHorizontalMargin)
        }
        
        if isButtonTextAvailable {
            bannerButton.snp.makeConstraints { make in
                make.top.equalTo(messageLabel.snp.bottom).offset(StandardVerticalMargin * 2)
                make.bottom.equalTo(container).inset(StandardVerticalMargin * 2)
                make.height.equalTo(buttonHeight)
                make.leading.equalTo(container).offset(StandardHorizontalMargin)
                make.trailing.equalTo(container).inset(StandardHorizontalMargin)
            }
        }
    }
    
    private func populate() {
        guard let bannerInfo = bannerInfo, let status = bannerInfo.status else { return }
        
        let headerText = bannerHeaderStyle.attributedString(withText: status.header)
        let bodyText = bannerBodyStyle.attributedString(withText: status.body).setLineSpacing(3)
        
        let messageText = [headerText, bodyText]
        let attributedString = NSAttributedString.joinInNaturalLayout(attributedStrings: messageText)
        
        messageLabel.attributedText = attributedString
        messageLabel.sizeToFit()
        messageLabel.layoutIfNeeded()
        messageLabel.setNeedsLayout()
        
        if isButtonTextAvailable {
            let buttonText = buttonStyle.attributedString(withText: status.button)
            bannerButton.setAttributedTitle(buttonText, for: .normal)
        }
    }
    
    @objc private func bannerButtonAction() {
        guard let bannerInfo = bannerInfo else { return }
                
        if bannerInfo.status == .resetDatesBanner {
            delegate?.courseShiftDateButtonAction()
        }
    }
}
