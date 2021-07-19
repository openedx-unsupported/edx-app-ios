//
//  ValuePropUpgradeButtonView.swift
//  edX
//
//  Created by Muhammad Umer on 13/07/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import UIKit

class ValuePropUpgradeButtonView: UIView {
    static var height: CGFloat = {
        return OEXConfig.shared().IAPEnabled ? 36 : 0
    }()
        
    private lazy var upgradeButton: UIButton = {
        let button = UIButton()
        button.isAccessibilityElement = false
        button.backgroundColor = OEXStyles.shared().secondaryBaseColor()
        button.oex_addAction({ [weak self] _ in
            self?.tapAction?()
        }, for: .touchUpInside)
        
        let buttonTitle = Strings.ValueProp.upgradeCourseFor(price: "99")
        
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
            style.attributedString(withText: buttonTitle)
        ]
        let buttonAttributedTitle = NSAttributedString.joinInNaturalLayout(attributedStrings: attributedStrings)
        button.setAttributedTitle(buttonAttributedTitle, for: .normal)
        button.contentVerticalAlignment = .center
        
        return button
    }()
    
    var tapAction : (() -> ())?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupView() {
        addSubview(upgradeButton)

        accessibilityTraits = .button
        isAccessibilityElement = true
        accessibilityLabel = Strings.ValueProp.upgradeCourseFor(price: "99")
        accessibilityHint = Strings.Accessibility.upgradeButtonHint
        
        upgradeButton.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }
}
