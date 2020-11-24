//
//  PopCardView.swift
//  edX
//
//  Created by Salman on 18/11/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import UIKit

class UpgradeValuePropView: UIView {

    let messageContainer = UIView()
    let iconContainer = UIView()
    let messageLabel = UILabel()
    let learnMoreButton = UIButton()
    let trophyImage = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame : frame)
        configureView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureView() {
        addSubview(iconContainer)
        addSubview(messageContainer)
        messageContainer.addSubview(messageLabel)
        messageContainer.addSubview(learnMoreButton)
        iconContainer.addSubview(trophyImage)
        
        learnMoreButton.layer.masksToBounds = true
        learnMoreButton.layer.cornerRadius = 5.0
        let learnMoreButtonTextStyle = OEXTextStyle(weight: .normal, size: .small, color : OEXStyles.shared().neutralWhite())
        learnMoreButton.setAttributedTitle(learnMoreButtonTextStyle.attributedString(withText: "Learn more"), for: .normal)
        learnMoreButton.backgroundColor = UIColor(hexString: "#5E35B1", alpha: 1.0)
        
        learnMoreButton.oex_addAction({[weak self] (action) in
            print("clicked")
            }, for: UIControl.Event.touchUpInside)
        
        messageLabel.numberOfLines = 4
        messageLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultHigh, for: NSLayoutConstraint.Axis.horizontal)
        messageLabel.adjustsFontSizeToFitWidth = true
        let fontstyle = OEXTextStyle(weight: .normal, size: .base, color : UIColor(hexString: "#5F35B1", alpha: 1.0))
        messageLabel.attributedText = fontstyle.attributedString(withText: "Get the most of out your course! Upgrade to get full access to the course material, unlock both graded and non-graded assignments, and earn a verified certificate to showcase on your resume.")

        trophyImage.image = Icon.Trophy.imageWithFontSize(size: 50)
        setUpConstraints()
    }
    
    private func setUpConstraints() {
        iconContainer.snp.makeConstraints { make in
            make.leading.equalTo(self)
            make.top.equalTo(self)
            make.height.equalTo(self)
            make.width.equalTo(40)
        }
        
        messageContainer.snp.makeConstraints { make in
            make.leading.equalTo(iconContainer.snp.trailing)
            make.top.equalTo(self)
            make.trailing.equalTo(self)
            make.height.equalTo(self)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.leading.equalTo(messageContainer).offset(StandardVerticalMargin)
            make.top.equalTo(messageContainer).offset(StandardVerticalMargin)
            make.trailing.equalTo(messageContainer).offset(-StandardVerticalMargin)
        }
        
        learnMoreButton.snp.makeConstraints { make in
            make.leading.equalTo(messageContainer).offset(StandardVerticalMargin)
            make.top.equalTo(messageLabel.snp.bottom)
            make.bottom.bottomMargin.equalTo(-StandardVerticalMargin)
            make.height.equalTo(30)
            make.width.equalTo(100)
        }
        
        trophyImage.snp.makeConstraints { make in
            make.leading.equalTo(iconContainer).offset(StandardVerticalMargin)
            make.top.equalTo(iconContainer).offset(StandardHorizontalMargin + 5)
            make.height.equalTo(30)
            make.width.equalTo(30)
        }
    }
}
