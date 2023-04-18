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
    private let attributedIconOfset: CGFloat = -4
    private let attributedUnicodeSpace = NSAttributedString(string: "\u{2002}")
    
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
        label.alpha = 0
        return label
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "CourseContentHeaderView:title-label"
        label.backgroundColor = .clear
        return label
    }()
    
    private lazy var subtitleView: UITextView = {
        let textView = UITextView()
        textView.accessibilityIdentifier = "CourseContentHeaderView:subtitle-label"
        textView.isEditable = false
        textView.isSelectable = true
        textView.isUserInteractionEnabled = true
        textView.backgroundColor = .clear
        textView.isScrollEnabled = false
        let padding = textView.textContainer.lineFragmentPadding
        textView.textContainerInset = UIEdgeInsets(top: 0, left: -padding, bottom: 0, right: -padding)
        
        let tapGesture = AttachmentTapGestureRecognizer { [weak self] _ in
            print("yeeee")
            //self?.delegate?.didTapOnShareCourse()
        }
        
        textView.addGestureRecognizer(tapGesture)
        
        return textView
    }()
    
    init(environment: Environment) {
        self.environment = environment
        super.init(frame: .zero)
        addSubViews()
        addConstraints()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addSubViews() {
        backgroundColor = environment.styles.primaryLightColor()
        
        addSubview(backButton)
        addSubview(headerLabel)
        addSubview(titleLabel)
        addSubview(subtitleView)
    }
    
    private func addConstraints() {
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
        
        subtitleView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(StandardVerticalMargin / 2)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.trailing.equalTo(self).inset(StandardHorizontalMargin)
        }
    }
    
    func showHeaderLabel(show: Bool) {
        headerLabel.alpha = show ? 1 : 0
    }
    
    func setup(title: String, subtitle: String?) {
        headerLabel.attributedText = titleTextStyle.attributedString(withText: title)
        titleLabel.attributedText = titleTextStyle.attributedString(withText: title)
        
        let subtitleTextString = [
            subtitleTextStyle.attributedString(withText: title),
            attributedUnicodeSpace,
            Icon.Dropdown.attributedText(style: subtitleTextStyle, yOffset: attributedIconOfset)
        ]
        
        subtitleView.attributedText = NSAttributedString.joinInNaturalLayout(attributedStrings: subtitleTextString)
    }
}
