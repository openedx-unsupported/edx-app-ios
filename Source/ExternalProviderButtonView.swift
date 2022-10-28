//
//  ExternalProviderButtonView.swift
//  edX
//
//  Created by MuhammadUmer on 28/10/2022.
//  Copyright © 2022 edX. All rights reserved.
//

import UIKit

class ExternalProviderButtonView: UIView {
    private let iconImage: UIImage
    private let text: String
    private let textStyle: OEXTextStyle
    private let providerColor: UIColor
    private let borderColor: UIColor?
    
    
    @objc init(iconImage: UIImage, text: String, textStyle: OEXTextStyle, backgroundColor: UIColor, borderColor: UIColor? = nil) {
        self.iconImage = iconImage
        self.text = text
        self.textStyle = textStyle
        self.providerColor = backgroundColor
        self.borderColor = borderColor
        super.init(frame: .zero)
        addSubViews()
    }
    
    private func addSubViews() {
        let iconImageView = UIImageView(image: iconImage)
        iconImageView.contentMode = .scaleAspectFit
        let label = UILabel()
        
        backgroundColor = providerColor
        addSubview(iconImageView)
        addSubview(label)
        
        label.attributedText = textStyle.attributedString(withText: text)
        
        if let borderColor = borderColor {
            layer.borderWidth = 1
            layer.borderColor = borderColor.cgColor
        }
        
        iconImageView.snp.makeConstraints { make in
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.height.equalTo(24)
            make.width.equalTo(24)
            make.centerY.equalTo(self)
        }
        
        label.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(StandardHorizontalMargin)
            make.trailing.equalTo(self)
            make.height.equalTo(19)
            make.centerY.equalTo(self)
        }
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
