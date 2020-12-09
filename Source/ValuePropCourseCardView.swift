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
    
    private lazy var messageLabel: UILabel = {
        let message = UILabel()
        message.numberOfLines = 0
        message.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: NSLayoutConstraint.Axis.horizontal)
        message.adjustsFontSizeToFitWidth = true
        let messageStyle = OEXTextStyle(weight: .normal, size: .base, color : OEXStyles.shared().neutralBlackT())
        message.attributedText = messageStyle.attributedString(withText: Strings.ValueProp.courseCardMessage)
        return message
    }()
    
    private lazy var learnMoreButton: UIButton = {
        let button = UIButton()
        let buttonTextStyle = OEXTextStyle(weight: .semiBold, size: .small, color : OEXStyles.shared().neutralWhiteT())
        button.setAttributedTitle(buttonTextStyle.attributedString(withText: Strings.ValueProp.learnMoreButtonTitle), for: .normal)
        button.backgroundColor = OEXStyles.shared().primaryBaseColor()
        return button
    }()
    private let trophyImage = UIImageView()
    private let trophyImageSize:CGSize = CGSize(width: 30, height: 30)
    private let learnMoreButtonSize:CGSize = CGSize(width: 100, height: 30)
    var tapAction : ((ValuePropCourseCardView) -> ())?
    
    override init(frame: CGRect) {
        super.init(frame : frame)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        addSubview(containerView)
        containerView.addSubview(messageLabel)
        containerView.addSubview(learnMoreButton)
        containerView.addSubview(trophyImage)
        
        learnMoreButton.oex_addAction({[weak self] action in
                if let weakSelf = self {
                    weakSelf.tapAction?(weakSelf)
                }
            }, for: .touchUpInside)
        
        trophyImage.image = Icon.Trophy.imageWithFontSize(size: trophyImageSize.height)
        setConstraints()
        setAccessibilityIdentifiers()
    }
    
    private func setAccessibilityIdentifiers() {
        containerView.accessibilityIdentifier = "ValuePropView:container-view"
        messageLabel.accessibilityIdentifier = "ValuePropView:message-label"
        trophyImage.accessibilityIdentifier = "ValuePropView:trophy-image"
        learnMoreButton.accessibilityIdentifier = "ValuePropView:learn-more-button"
    }
    
    private func setConstraints() {
        containerView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.leading.equalTo(trophyImage.snp.trailing).offset(StandardVerticalMargin)
            make.top.equalTo(containerView).offset(StandardVerticalMargin)
            make.trailing.equalTo(containerView).inset(StandardVerticalMargin)
        }
        
        learnMoreButton.snp.makeConstraints { make in
            make.top.equalTo(messageLabel.snp.bottom).offset(StandardVerticalMargin)
            make.bottom.equalTo(containerView).inset(StandardVerticalMargin)
            make.trailing.equalTo(containerView).inset(StandardVerticalMargin)
            make.height.equalTo(learnMoreButtonSize.height)
            make.width.equalTo(learnMoreButtonSize.width)
        }
        
        trophyImage.snp.makeConstraints { make in
            make.leading.equalTo(containerView).offset(StandardVerticalMargin)
            make.top.equalTo(containerView).offset(StandardVerticalMargin)
            make.height.equalTo(trophyImageSize.height)
            make.width.equalTo(trophyImageSize.width)
        }
    }
}
