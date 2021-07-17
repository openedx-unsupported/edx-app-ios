//
//  ValuePropCourseCardView.swift
//  edX
//
//  Created by Salman on 18/11/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import UIKit

class ValuePropCourseCardView: UIView {

    private let containerView = UIView()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        label.adjustsFontSizeToFitWidth = true
        let style = OEXTextStyle(weight: .bold, size: .small, color : OEXStyles.shared().neutralWhiteT())
        label.attributedText = style.attributedString(withText: Strings.ValueProp.courseCardMessage)
        return label
    }()
    
    private lazy var tapButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .clear
        button.accessibilityLabel = Strings.ValueProp.courseCardMessage
        button.accessibilityHint = Strings.Accessibility.buttonActionHint
        return button
    }()
    private let lockImageView = UIImageView()
    private let chevronImageView = UIImageView()
    private let lockImageSize: CGFloat = 14
    var tapAction: (() -> ())?
    
    override init(frame: CGRect) {
        super.init(frame : frame)
        setupViews()
        setConstraints()
        setAccessibilityIdentifiers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(lockImageView)
        containerView.addSubview(chevronImageView)
        containerView.addSubview(tapButton)
        
        tapButton.oex_addAction({[weak self] action in
                self?.tapAction?()
            }, for: .touchUpInside)
        
        lockImageView.image = Icon.Closed.imageWithFontSize(size: 14)
        lockImageView.tintColor = OEXStyles.shared().neutralWhiteT()

        chevronImageView.image = Icon.ChevronRight.imageWithFontSize(size: 20)
        chevronImageView.tintColor = OEXStyles.shared().accentAColor()

        lockImageView.isAccessibilityElement = false
        titleLabel.isAccessibilityElement = false
        chevronImageView.isAccessibilityElement = false

    }
    
    private func setAccessibilityIdentifiers() {
        containerView.accessibilityIdentifier = "ValuePropView:container-view"
        titleLabel.accessibilityIdentifier = "ValuePropView:title-label"
        lockImageView.accessibilityIdentifier = "ValuePropView:lock-image"
        chevronImageView.accessibilityIdentifier = "ValuePropView:chevron-image"
        tapButton.accessibilityIdentifier = "ValuePropView:tap-button"
    }
    
    private func setConstraints() {
        containerView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }

        lockImageView.snp.makeConstraints { make in
            make.leading.equalTo(containerView).offset(StandardHorizontalMargin)
            make.height.equalTo(lockImageSize)
            make.width.equalTo(lockImageSize)
            make.centerY.equalTo(containerView)
        }

        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(lockImageView.snp.trailing).offset(StandardVerticalMargin)
            make.trailing.lessThanOrEqualTo(chevronImageView).inset(StandardHorizontalMargin)
            make.centerY.equalTo(lockImageView)
        }

        chevronImageView.snp.makeConstraints { make in
            make.trailing.equalTo(containerView).inset(StandardHorizontalMargin)
            make.centerY.equalTo(lockImageView)
        }
        
        tapButton.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }
}
