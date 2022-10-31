//
//  ExternalProviderButtonView.swift
//  edX
//
//  Created by MuhammadUmer on 28/10/2022.
//  Copyright © 2022 edX. All rights reserved.
//

import UIKit

class ExternalProviderButtonView: UIView {
    private let imageSize = 24
    private let textHeight = 19
    
    @objc init(iconImage: UIImage, title: String, textStyle: OEXTextStyle, backgroundColor: UIColor, borderColor: UIColor? = nil) {
        super.init(frame: .zero)
        configureAuthButtonView(iconImage: iconImage, title: title, textStyle: textStyle, providerColor: backgroundColor, borderColor: borderColor)
    }
    
    private func configureAuthButtonView(iconImage: UIImage, title: String, textStyle: OEXTextStyle, providerColor: UIColor, borderColor: UIColor? = nil) {
        let iconImageView = UIImageView(image: iconImage)
        iconImageView.contentMode = .scaleAspectFit
        let buttonTitle = UILabel()
        
        backgroundColor = providerColor
        addSubview(iconImageView)
        addSubview(buttonTitle)
        
        buttonTitle.attributedText = textStyle.attributedString(withText: title)
        
        if let borderColor = borderColor {
            layer.borderWidth = 1
            layer.borderColor = borderColor.cgColor
        }
        
        iconImageView.snp.makeConstraints { make in
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.height.equalTo(imageSize)
            make.width.equalTo(imageSize)
            make.centerY.equalTo(self)
        }
        
        buttonTitle.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(StandardHorizontalMargin)
            make.trailing.equalTo(self)
            make.height.equalTo(textHeight)
            make.centerY.equalTo(self)
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
