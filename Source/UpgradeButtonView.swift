//
//  UpgradeButtonView.swift
//  edX
//
//  Created by Muhammad Umer on 13/07/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import UIKit

protocol UpgradeButtonDelegate: AnyObject {
    func didTapOnButton()
}

class UpgradeButtonView: UIView {
    static var height: CGFloat = {
        return OEXConfig.shared().inappPurchasesEnabled ? 36 : 0
    }()
    
    weak var delegate: UpgradeButtonDelegate?
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.accessibilityIdentifier = "UpgradeButtonView:title-label"
        return label
    }()
    
    private lazy var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = OEXStyles.shared().neutralWhiteT()
        activityIndicator.accessibilityIdentifier = "UpgradeButtonView:activity-indicator"
        return activityIndicator
    }()
    
    private lazy var backgroundButton: UIButton = {
        let button = UIButton()
        button.oex_addAction({ [weak self] _ in
            self?.delegate?.didTapOnButton()
        }, for: .touchUpInside)
        button.accessibilityIdentifier = "UpgradeButtonView:background-button"
        return button
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupViews()
        addConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(titleLabel)
        addSubview(activityIndicator)
        addSubview(backgroundButton)
        
        backgroundColor = OEXStyles.shared().secondaryBaseColor()
        
        accessibilityTraits = .button
        isAccessibilityElement = true
        accessibilityLabel = Strings.ValueProp.upgradeCourseFor(price: "99")
        accessibilityHint = Strings.Accessibility.upgradeButtonHint
        
        isHidden = OEXConfig.shared().inappPurchasesEnabled ? false : true
    }
    
    private func addConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
        
        activityIndicator.snp.makeConstraints { make in
            make.top.equalTo(self)
            make.bottom.equalTo(self)
            make.centerX.equalTo(self)
        }
        
        backgroundButton.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }
    
    func setPrice(_ price: String) {
        // view will be visisble for a valid price
        isHidden = price.isEmpty
        titleLabel.isHidden = price.isEmpty
        
        let title = Strings.ValueProp.upgradeCourseFor(price: price)
        
        let lockedImage = Icon.Closed.imageWithFontSize(size: 16).image(with: OEXStyles.shared().neutralWhiteT())
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = lockedImage
        let imageOffsetY: CGFloat = -2.0
        if let image = imageAttachment.image {
            imageAttachment.bounds = CGRect(x: 0, y: imageOffsetY, width: image.size.width, height: image.size.height)
        }
        
        let attributedImageString = NSAttributedString(attachment: imageAttachment)
        let style = OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().neutralWhiteT())
        let attributedStrings = [
            attributedImageString,
            NSAttributedString(string: "\u{2000}"),
            style.attributedString(withText: title)
        ]
        let attributedTitle = NSAttributedString.joinInNaturalLayout(attributedStrings: attributedStrings)
        titleLabel.attributedText = attributedTitle
    }
    
    func startAnimating() {
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
        titleLabel.isHidden = true
    }
    
    func stopAnimating() {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        titleLabel.isHidden = false
    }
    
    func updateVisibility(visible: Bool) {
        isHidden = !visible
    }
}

