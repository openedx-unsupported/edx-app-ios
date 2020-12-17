//
//  ValuePropMessageView.swift
//  edX
//
//  Created by Muhammad Umer on 08/12/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import Foundation

protocol ValuePropMessageViewDelegate {
    func showValuePropDetailView()
}

class ValuePropMessageView: UIView {
    
    typealias Environment = OEXStylesProvider
        
    var delegate: ValuePropMessageViewDelegate?
        
    private let imageSize: CGFloat = 20
    
    private lazy var container = UIView()
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        return label
    }()
    private lazy var buttonLearnMore = UIButton()
    private lazy var lockImageView = UIImageView()
    
    private lazy var titleStyle: OEXMutableTextStyle = {
        return OEXMutableTextStyle(weight: .bold, size: .large, color: environment.styles.primaryDarkColor())
    }()
    
    private lazy var messageStyle: OEXMutableTextStyle = {
        return OEXMutableTextStyle(weight: .normal, size: .base, color: environment.styles.primaryDarkColor())
    }()
    
    private lazy var buttonStyle: OEXMutableTextStyle = {
        return OEXMutableTextStyle(weight: .semiBold, size: .small, color: OEXStyles.shared().neutralWhiteT())
    }()
    
    private let environment: Environment
        
    init(environment: Environment) {
        self.environment = environment
        super.init(frame: .zero)
        
        setupViews()
        setConstraints()
        setAccessibilityIdentifiers()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        container.backgroundColor = environment.styles.infoXXLight()
        
        lockImageView.image = Icon.Closed.imageWithFontSize(size: imageSize).image(with: environment.styles.primaryDarkColor())
        titleLabel.attributedText = titleStyle.attributedString(withText: Strings.ValueProp.assignmentsAreLocked)
        messageLabel.attributedText = messageStyle.attributedString(withText: Strings.ValueProp.upgradeToAccessGraded)

        buttonLearnMore.backgroundColor = environment.styles.primaryBaseColor()
        buttonLearnMore.setAttributedTitle(buttonStyle.attributedString(withText: Strings.ValueProp.learnMore), for: UIControl.State())
        buttonLearnMore.oex_addAction({ [weak self] _ in
            self?.delegate?.showValuePropDetailView()
        }, for: .touchUpInside)
        
        container.addSubview(titleLabel)
        container.addSubview(messageLabel)
        container.addSubview(buttonLearnMore)
        container.addSubview(lockImageView)
        addSubview(container)
    }
    
    private func setConstraints() {
        container.snp.makeConstraints { make in
            make.top.equalTo(self)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.trailing.equalTo(self).inset(StandardHorizontalMargin)
            make.bottom.equalTo(buttonLearnMore).offset(StandardVerticalMargin * 2)
        }
        
        lockImageView.snp.makeConstraints { make in
            make.top.equalTo(StandardVerticalMargin * 2)
            make.leading.equalTo(container).offset(StandardHorizontalMargin + 4)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(lockImageView)
            make.leading.equalTo(container).offset(StandardHorizontalMargin * 4)
            make.trailing.equalTo(container)
            make.width.equalTo(container)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(StandardVerticalMargin * 2)
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(container).inset(StandardHorizontalMargin * 2)
        }
        
        buttonLearnMore.snp.makeConstraints { make in
            make.top.equalTo(messageLabel.snp.bottom).offset(StandardVerticalMargin * 2)
            make.height.equalTo(StandardVerticalMargin * 4)
            make.trailing.equalTo(container).inset(StandardHorizontalMargin * 2)
            make.width.equalTo(StandardHorizontalMargin * 6)
        }
    }
    
    private func setAccessibilityIdentifiers() {
        accessibilityIdentifier = "ValuePropMessageView:view"
        lockImageView.accessibilityIdentifier = "ValuePropMessageView:image-view-lock"
        titleLabel.accessibilityIdentifier = "ValuePropMessageView:label-title"
        messageLabel.accessibilityIdentifier = "ValuePropMessageView:label-message"
        buttonLearnMore.accessibilityIdentifier = "ValuePropMessageView:button-learn-more"
    }
}
