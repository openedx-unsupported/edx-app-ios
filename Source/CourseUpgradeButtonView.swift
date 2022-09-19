//
//  CourseUpgradeButtonView.swift
//  edX
//
//  Created by Muhammad Umer on 13/07/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import UIKit

class CourseUpgradeButtonView: UIView, ShimmerView {
    var height: CGFloat = {
        return ServerConfiguration.shared.iapConfig?.enabledforUser ?? false ? 36 : 0
    }()
        
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
    
    private lazy var button: UIButton = {
        let button = UIButton()
        button.oex_addAction({ [weak self] _ in
            self?.startAnimating()
            self?.tapAction?()
        }, for: .touchUpInside)
        button.accessibilityIdentifier = "UpgradeButtonView:background-button"
        return button
    }()
    
    var tapAction: (() -> ())?
        
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
        addSubview(button)

        accessibilityTraits = .button
        isAccessibilityElement = true
        accessibilityHint = Strings.Accessibility.upgradeButtonHint
        
        isHidden = ServerConfiguration.shared.iapConfig?.enabledforUser ?? false
    }
    
    private func addConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.top.equalTo(self).offset(-2)
            make.bottom.equalTo(self)
        }
        
        activityIndicator.snp.makeConstraints { make in
            make.center.equalTo(self)
        }
        
        button.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }
    
    func setPrice(_ price: String) {
        // view will be visisble for a valid price
        isHidden = price.isEmpty
        accessibilityLabel = Strings.ValueProp.upgradeCourseFor(price: price)
        
        let title = Strings.ValueProp.upgradeCourseFor(price: price)
        
        let lockedImage = Icon.Closed.imageWithFontSize(size: 20).image(with: OEXStyles.shared().neutralWhiteT())
        let imageAttachment = NSTextAttachment()
        imageAttachment.image = lockedImage
        if let image = imageAttachment.image {
            imageAttachment.bounds = CGRect(x: 0, y: -3, width: image.size.width, height: image.size.height)
        }
        
        let attributedImageString = NSAttributedString(attachment: imageAttachment)
        let style = OEXTextStyle(weight: .bold, size: .base, color: OEXStyles.shared().neutralWhiteT())
        let attributedStrings = [
            attributedImageString,
            NSAttributedString(string: "\u{200b}"),
            style.attributedString(withText: title)
        ]
        let attributedTitle = NSAttributedString.joinInNaturalLayout(attributedStrings: attributedStrings)
        titleLabel.attributedText = attributedTitle
    }
    
    func startShimeringEffect() {
        isHidden = false
        isUserInteractionEnabled = false
        setShimmerAnimation(true, shimmerColor: OEXStyles.shared().neutralBase())
    }
    
    func stopShimmerEffect() {
        isUserInteractionEnabled = true
        removeShimmerAnimation(backgroundColor: OEXStyles.shared().secondaryBaseColor())
    }
    
    func startAnimating() {
        button.isUserInteractionEnabled = false
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
        titleLabel.isHidden = true
    }
    
    func stopAnimating() {
        button.isUserInteractionEnabled = true
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        titleLabel.isHidden = false
    }
    
    func updateVisibility(visible: Bool) {
        isHidden = !visible
    }
}

