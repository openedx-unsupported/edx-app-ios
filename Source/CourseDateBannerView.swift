//
//  CourseDateBannerView.swift
//  edX
//
//  Created by Muhammad Umer on 08/09/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import UIKit

private let cornerRadius: CGFloat = 5

protocol CourseDateBannerViewDelegate {
    func courseShiftDateButtonAction()
}

class CourseDateBannerView: UIView {
    
    private let buttonMinWidth: CGFloat = 80
    private var buttonContainerHeight: CGFloat {
        return isiPad ? 80 : 60
    }
    
    private lazy var container = UIView()
    private lazy var stackView = UIStackView()
    private lazy var labelContainer = UIView()
    private lazy var buttonContainer = UIView()
    
    private lazy var messageLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var bannerHeaderStyle: OEXMutableTextStyle = {
        let style = OEXMutableTextStyle(weight: .bold, size: .small, color: OEXStyles.shared().neutralBlack())
        style.lineBreakMode = .byWordWrapping
        return style
    }()
    
    private lazy var bannerBodyStyle: OEXMutableTextStyle = {
        let style = OEXMutableTextStyle(weight: .light, size: .small, color: OEXStyles.shared().neutralBlack())
        style.lineBreakMode = .byWordWrapping
        return style
    }()
    
    private lazy var buttonStyle: OEXMutableTextStyle = {
        return OEXMutableTextStyle(weight: .semiBold, size: .base, color: OEXStyles.shared().neutralBlack())
    }()
    
    private lazy var bannerButton: UIButton = {
        let button = UIButton()
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        button.layer.backgroundColor = OEXStyles.shared().neutralWhiteT().cgColor
        button.layer.borderColor = OEXStyles.shared().neutralXDark().cgColor
        button.layer.borderWidth = 1
        button.layer.cornerRadius = cornerRadius
        button.oex_removeAllActions()
        button.oex_addAction({ [weak self] _ in
            self?.bannerButtonAction()
            }, for: .touchUpInside)
        return button
    }()
    
    private var isButtonTextAvailable: Bool {
        guard let bannerInfo = bannerInfo, let status = bannerInfo.status else { return false }
        return !status.button.isEmpty
    }
    
    var bannerInfo: DatesBannerInfo?
    var delegate: CourseDateBannerViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setupView() {
        configureViews()
        applyConstraints()
        setAccessibilityIdentifiers()
        populate()
    }
    
    private func configureViews() {
        stackView.subviews.forEach { $0.removeFromSuperview() }
        stackView.superview?.removeFromSuperview()
        labelContainer.superview?.removeFromSuperview()
        container.superview?.removeFromSuperview()
        
        backgroundColor = OEXStyles.shared().primaryXLightColor()
        addSubview(container)
        
        stackView.alignment = .leading
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.spacing = StandardVerticalMargin / 2
        stackView.addArrangedSubview(labelContainer)
        
        labelContainer.setContentHuggingPriority(.defaultLow, for: .vertical)
        
        labelContainer.addSubview(messageLabel)
        container.addSubview(stackView)
        
        if isButtonTextAvailable {
            stackView.addArrangedSubview(buttonContainer)
            buttonContainer.addSubview(bannerButton)
            
            buttonContainer.setContentHuggingPriority(.defaultHigh, for: .vertical)
        }
    }
    
    private func applyConstraints() {
        container.snp.makeConstraints { make in
            make.leading.equalTo(self).inset(StandardHorizontalMargin)
            make.trailing.equalTo(self).inset(StandardHorizontalMargin)
            make.top.equalTo(self)
            make.bottom.equalTo(self)
        }
        
        stackView.snp.makeConstraints { make in
            make.leading.equalTo(container)
            make.trailing.equalTo(container)
            make.top.equalTo(container)
            make.bottom.equalTo(container).inset(StandardVerticalMargin)
        }
        
        labelContainer.snp.makeConstraints { make in
            make.top.equalTo(stackView)
            make.width.equalTo(stackView)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.edges.equalTo(labelContainer)
        }
        
        if isButtonTextAvailable {
            buttonContainer.snp.makeConstraints { make in
                make.width.equalTo(stackView.snp.width)
                make.bottom.equalTo(stackView.snp.bottom)
            }
            
            bannerButton.snp.makeConstraints { make in
                make.trailing.equalTo(buttonContainer.snp.trailing)
                make.top.equalTo(buttonContainer.snp.top)
                make.bottom.equalTo(buttonContainer.snp.bottom)
                make.width.greaterThanOrEqualTo(buttonMinWidth)
            }
        }
    }
    
    private func setAccessibilityIdentifiers() {
        container.accessibilityIdentifier = "CourseResetDateBannerView:container-view"
        labelContainer.accessibilityIdentifier = "CourseResetDateBannerView:messagelabel-container"
        buttonContainer.accessibilityIdentifier = "CourseResetDateBannerView:reset-date-button-container"
        messageLabel.accessibilityIdentifier = "CourseResetDateBannerView:message-label"
        bannerButton.accessibilityIdentifier = "CourseResetDateBannerView:reset-date-button"
    }
    
    private func populate() {
        guard let bannerInfo = bannerInfo, let status = bannerInfo.status else { return }
        
        let headerText = bannerHeaderStyle.attributedString(withText: status.header)
        let bodyText = bannerBodyStyle.attributedString(withText: status.body)
        
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
    
    func heightForView(width: CGFloat) -> CGFloat {
        guard let bannerInfo = bannerInfo, let status = bannerInfo.status else { return 0 }

        let label = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: CGFloat.greatestFiniteMagnitude))
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = OEXStyles().boldSansSerif(ofSize: OEXTextStyle.pointSize(for: .base))
        label.text = status.header + status.body
        label.sizeToFit()
        
        return status.button.isEmpty ? label.frame.height + StandardVerticalMargin : label.frame.height + buttonContainerHeight
    }
}
