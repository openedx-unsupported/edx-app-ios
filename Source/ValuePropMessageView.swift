//
//  ValuePropMessageView.swift
//  edX
//
//  Created by Muhammad Umer on 08/12/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import Foundation

protocol ValuePropMessageViewDelegate {
    func valuePropMessageViewLearnMoreAction()
}

class ValuePropMessageView: UIView {
    
    typealias Environment = OEXStylesProvider
    
    var delegate: ValuePropMessageViewDelegate?
        
    private let imageSize: CGFloat = 20
    private let bannerViewHeight = StandardHorizontalMargin * 12
    private let leadingOffset = StandardHorizontalMargin * 4
    private let buttonHeight = StandardVerticalMargin * 4
    private let buttonMinimunWidth = StandardHorizontalMargin * 6
    
    private lazy var stackView = TZStackView()
    private lazy var titleContainer = UIView()
    private lazy var titleLabel = UILabel()
    private lazy var messageContainer = UIView()
    private lazy var buttonContainer = UIView()
    private lazy var buttonLearnMore = UIButton()
    private lazy var imageView = UIImageView()
    private lazy var messageLabel = UILabel()
    
    private lazy var titleStyle: OEXMutableTextStyle = {
        return OEXMutableTextStyle(weight: .bold, size: .large, color: environment.styles.primaryDarkColor())
    }()
    
    private lazy var messageStyle: OEXMutableTextStyle = {
        return OEXMutableTextStyle(weight: .normal, size: .base, color: environment.styles.primaryDarkColor())
    }()
    
    private lazy var buttonStyle: OEXMutableTextStyle = {
        return OEXMutableTextStyle(weight: .normal, size: .small, color: environment.styles.primaryDarkColor())
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
        backgroundColor = environment.styles.accentAColor()
        
        imageView.image = Icon.Closed.imageWithFontSize(size: imageSize).image(with: environment.styles.primaryDarkColor())
        
        titleLabel.numberOfLines = 0
        titleLabel.attributedText = titleStyle.attributedString(withText: Strings.courseContentGatedLocked)
        
        messageLabel.numberOfLines = 0
        messageLabel.attributedText = messageStyle.attributedString(withText: Strings.courseContentGatedUpgradeToAccessGraded)
        
        buttonLearnMore.backgroundColor = environment.styles.neutralWhiteT()
        buttonLearnMore.setAttributedTitle(buttonStyle.attributedString(withText: Strings.courseContentGatedLearnMore), for: UIControl.State())
        buttonLearnMore.oex_addAction({ [weak self] _ in
            self?.delegate?.valuePropMessageViewLearnMoreAction()
        }, for: .touchUpInside)
        
        titleContainer.addSubview(imageView)
        titleContainer.addSubview(titleLabel)
        messageContainer.addSubview(messageLabel)
        buttonContainer.addSubview(buttonLearnMore)
        addSubview(stackView)
    }
    
    private func setConstraints() {
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.alignment = .leading
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = StandardVerticalMargin / 2
        
        stackView.addArrangedSubview(titleContainer)
        stackView.addArrangedSubview(messageContainer)
        stackView.addArrangedSubview(buttonContainer)
                
        imageView.snp.makeConstraints { make in
            make.top.equalTo(StandardVerticalMargin * 2.2)
            make.leading.equalTo(self).offset(StandardHorizontalMargin + 4)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.edges.equalTo(titleContainer)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.edges.equalTo(messageContainer)
        }
        
        buttonLearnMore.snp.makeConstraints { make in
            make.height.equalTo(buttonHeight)
            make.bottom.equalTo(buttonContainer).inset(StandardVerticalMargin * 2)
            make.trailing.equalTo(buttonContainer).inset(StandardHorizontalMargin)
            make.width.greaterThanOrEqualTo(buttonMinimunWidth)
        }
        
        titleContainer.snp.makeConstraints { make in
            make.leading.equalTo(self).offset(leadingOffset)
            make.trailing.equalTo(self)
            make.width.equalTo(self)
            make.height.equalTo(frame.size.height / CGFloat(stackView.subviews.count))
        }
        
        messageContainer.snp.makeConstraints { make in
            make.leading.equalTo(self).offset(leadingOffset)
            make.trailing.equalTo(self).inset(StandardHorizontalMargin * 2)
            make.height.equalTo(frame.size.height / CGFloat(stackView.subviews.count))
        }
        
        buttonContainer.snp.makeConstraints { make in
            make.leading.equalTo(self).offset(leadingOffset)
            make.trailing.equalTo(self)
            make.height.equalTo(frame.size.height / CGFloat(stackView.subviews.count))
        }
        
        stackView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
    }
    
    private func setAccessibilityIdentifiers() {
        accessibilityIdentifier = "ValuePropMessageView:view"
        imageView.accessibilityIdentifier = "ValuePropMessageView:image-view"
        titleLabel.accessibilityIdentifier = "ValuePropMessageView:label-title"
        messageLabel.accessibilityIdentifier = "ValuePropMessageView:label-message"
        buttonLearnMore.accessibilityIdentifier = "ValuePropMessageView:button-learn-more"
    }
}
