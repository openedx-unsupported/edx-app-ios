//
//  CourseResetDateView.swift
//  edX
//
//  Created by Muhammad Umer on 08/09/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import UIKit

private let cornerRadius: CGFloat = 5

protocol CourseResetDateViewDelegate {
    func didSelectResetDatesButton()
}

class CourseResetDateView: UIView {
    private let labelMaxHeight: CGFloat = 200
    private let buttonMinWidth: CGFloat = 80
    private let buttonContainerMinHeight: CGFloat = 80
    
    private lazy var container = UIView()
    private lazy var stackView = UIStackView()
    private lazy var buttonContainer = UIView()
    
    private lazy var bannerLabel: UILabel = {
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
        button.configure(backgroundColor: OEXStyles.shared().neutralWhiteT(), borderColor: OEXStyles.shared().neutralXDark(), borderWith: 1, cornerRadius: cornerRadius)
        button.oex_addAction({ [weak self] _ in
            self?.actionResetDates()
            }, for: .touchUpInside)
        return button
    }()
    
    private var isButtonTextAvailable: Bool {
        guard let bannerInfo = bannerInfo, let status = bannerInfo.status else { return true }
        return !status.button.isEmpty
    }
    
    var bannerInfo: DatesBannerInfo?
    var delegate: CourseResetDateViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func setupView() {
        configureViews()
        applyContrains()
        setAccessibilityIdentifiers()
        populate()
    }
    
    private func configureViews() {
        backgroundColor = OEXStyles.shared().neutralLight()
        addSubview(container)
        stackView.alignment = .leading
        stackView.axis = .vertical
        stackView.spacing = StandardHorizontalMargin
        stackView.addArrangedSubview(bannerLabel)
        container.addSubview(stackView)
        
        if isButtonTextAvailable {
            stackView.addArrangedSubview(buttonContainer)
            buttonContainer.addSubview(bannerButton)
        }
    }
    
    private func applyContrains() {
        container.snp.makeConstraints { make in
            make.edges.equalTo(self).inset(StandardVerticalMargin)
        }
        
        stackView.snp.makeConstraints { make in
            make.edges.equalTo(container).inset(StandardVerticalMargin)
        }
        
        if isButtonTextAvailable {
            buttonContainer.snp.makeConstraints { make in
                make.width.equalTo(stackView.snp.width)
                make.bottom.equalTo(stackView.snp.bottom)
            }
            
            bannerButton.snp.makeConstraints { make in
                make.leading.equalTo(buttonContainer.snp.leading)
                make.top.equalTo(buttonContainer.snp.top)
                make.bottom.equalTo(buttonContainer.snp.bottom)
                make.width.greaterThanOrEqualTo(buttonMinWidth)
            }
        }
    }
    
    private func setAccessibilityIdentifiers() {
        bannerLabel.accessibilityIdentifier = "CourseResetDateView:banner-text-label"
        if isButtonTextAvailable {
            bannerButton.accessibilityIdentifier = "CourseResetDateView:reset-date-button"
        }
    }
    
    private func populate() {
        guard let bannerInfo = bannerInfo, let status = bannerInfo.status else { return }
        
        let headerText = bannerHeaderStyle.attributedString(withText: status.header)
        let bodyText = bannerBodyStyle.attributedString(withText: status.body)
        
        let attributedString = NSMutableAttributedString(attributedString: headerText)
        attributedString.append(bodyText)
        
        bannerLabel.attributedText = attributedString
        bannerLabel.sizeToFit()
        
        if isButtonTextAvailable {
            let buttonText = buttonStyle.attributedString(withText: status.button)
            bannerButton.setAttributedTitle(buttonText, for: .normal)
        }
    }
    
    @objc private func actionResetDates() {
        guard let bannerInfo = bannerInfo else { return }
                
        if bannerInfo.status == .resetDatesBanner {
            delegate?.didSelectResetDatesButton()
        }
    }
    
    func heightForView(width: CGFloat) -> CGFloat {
        guard let bannerInfo = bannerInfo, let status = bannerInfo.status else { return 0 }

        let label = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: labelMaxHeight))
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = OEXStyles().boldSansSerif(ofSize: OEXTextStyle.pointSize(for: .base))
        label.text = status.header + status.body
        label.sizeToFit()
        
        return status.button.isEmpty ? label.frame.height + (buttonContainerMinHeight / 2) : label.frame.height + buttonContainerMinHeight
    }
}


fileprivate extension UIView {
    func configure(backgroundColor: UIColor, borderColor: UIColor , borderWith: CGFloat, cornerRadius: CGFloat) {
        layer.backgroundColor = backgroundColor.cgColor
        layer.borderWidth = borderWith
        layer.borderColor = borderColor.cgColor
        layer.cornerRadius = cornerRadius
    }
}
