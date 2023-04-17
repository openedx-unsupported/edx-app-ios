//
//  CourseContentHeaderView.swift
//  edX
//
//  Created by MuhammadUmer on 11/04/2023.
//  Copyright © 2023 edX. All rights reserved.
//

import UIKit

protocol CourseContentHeaderViewDelegate: AnyObject {
    func didTapOnClose()
}

class CourseContentHeaderView: UIView {
    typealias Environment = OEXStylesProvider
    
    weak var delegate: CourseContentHeaderViewDelegate?
    
    private let environment: Environment
    
    private let imageSize: CGFloat = 20
    
    private lazy var titleTextStyle = OEXMutableTextStyle(weight: .normal, size: .base, color: environment.styles.neutralWhiteT())
    private lazy var subtitleTextStyle = OEXMutableTextStyle(weight: .bold, size: .large, color: environment.styles.neutralWhiteT())
    
    private lazy var backButton: UIButton = {
        let button = UIButton()
        button.accessibilityIdentifier = "CourseContentHeaderView:back-button"
        button.setImage(Icon.ArrowBack.imageWithFontSize(size: imageSize), for: .normal)
        button.tintColor = environment.styles.neutralWhiteT()
        button.oex_addAction({ [weak self] _ in
            self?.delegate?.didTapOnClose()
        }, for: .touchUpInside)
        return button
    }()
    
    private lazy var headerLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "CourseContentHeaderView:header-label"
        label.backgroundColor = .clear
        return label
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "CourseContentHeaderView:title-label"
        label.backgroundColor = .clear
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "CourseContentHeaderView:subtitle-label"
        label.backgroundColor = .clear
        return label
    }()
    
    init(environment: Environment) {
        self.environment = environment
        super.init(frame: .zero)
        setupSubviews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubviews() {
        backgroundColor = environment.styles.primaryLightColor()
        
        addSubview(backButton)
        addSubview(headerLabel)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        
        headerLabel.alpha = 0
        
        backButton.snp.makeConstraints { make in
            make.leading.equalTo(self).inset(StandardHorizontalMargin * 0.86)
            make.top.equalTo(self).offset(StandardVerticalMargin * 1.25)
            make.width.height.equalTo(imageSize)
        }
        
        headerLabel.snp.makeConstraints { make in
            make.top.equalTo(backButton)
            make.leading.equalTo(backButton.snp.trailing).offset(StandardHorizontalMargin)
            make.trailing.equalTo(self).inset(StandardHorizontalMargin)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(backButton.snp.bottom).offset(StandardVerticalMargin * 2)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.trailing.equalTo(self).inset(StandardHorizontalMargin)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(StandardVerticalMargin / 2)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.trailing.equalTo(self).inset(StandardHorizontalMargin)
        }        
    }
    
    func showHeaderLabel(show: Bool) {
        headerLabel.alpha = show ? 1 : 0
    }
    
    func setup(title: String, subtitle: String?) {
        titleLabel.attributedText = titleTextStyle.attributedString(withText: title)
        headerLabel.attributedText = titleTextStyle.attributedString(withText: title)
        subtitleLabel.attributedText = subtitleTextStyle.attributedString(withText: subtitle)
    }
}
