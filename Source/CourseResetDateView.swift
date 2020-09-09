//
//  CourseResetDateView.swift
//  edX
//
//  Created by Muhammad Umer on 08/09/2020.
//  Copyright © 2020 edX. All rights reserved.
//

import UIKit

private let cornerRadius: CGFloat = 5

class CourseResetDateView: UIView {
    private let maxHeight: CGFloat = 200
    
    private lazy var container = UIView()
    private lazy var stackView = UIStackView()
    private lazy var buttonContainer = UIView()
    
    private lazy var bannerLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var bannerStyle: OEXMutableTextStyle = {
        let style = OEXMutableTextStyle(weight: .bold, size: .small, color: OEXStyles.shared().neutralBlack())
        style.lineBreakMode = .byWordWrapping
        return style
    }()
    
    private lazy var buttonStyle: OEXMutableTextStyle = {
        return OEXMutableTextStyle(weight: .semiBold, size: .base, color: OEXStyles.shared().neutralBlack())
    }()
    
    private lazy var bannerButton: UIButton = {
       let button = UIButton()
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 15, bottom: 10, right: 15)
        button.configure(backgroundColor: OEXStyles.shared().neutralWhiteT(), borderColor: OEXStyles.shared().neutralXDark(), borderWith: 1, cornerRadius: cornerRadius)
        return button
    }()
    
    var bannerText: String? {
        didSet {
            guard let bannerText = bannerText else { return }
            bannerLabel.attributedText = bannerStyle.attributedString(withText: bannerText)
            bannerLabel.sizeToFit()
            
            let buttonText = buttonStyle.attributedString(withText: "Shift due dates")
            bannerButton.setAttributedTitle(buttonText, for: .normal)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setupView()
    }
    
    private func setupView() {
        configureViews()
        applyContrains()
        setAccessibilityIdentifiers()
    }
    
    private func configureViews() {
        backgroundColor = OEXStyles.shared().neutralLight()

        addSubview(container)
                        
        stackView.alignment = .leading
        stackView.axis = .vertical
        stackView.spacing = (StandardHorizontalMargin)
        
        stackView.addArrangedSubview(bannerLabel)
        stackView.addArrangedSubview(buttonContainer)
        
        container.addSubview(stackView)
        
        buttonContainer.addSubview(bannerButton)
    }
    
    private func applyContrains() {
        container.snp.makeConstraints { make in
            make.edges.equalTo(self).inset(StandardVerticalMargin)
        }
        
        stackView.snp.makeConstraints { make in
            make.edges.equalTo(container).inset(StandardVerticalMargin)
        }
        
        bannerButton.snp.makeConstraints { make in
            make.leading.equalTo(buttonContainer.snp.leading)
            make.top.equalTo(buttonContainer.snp.top)
            make.bottom.equalTo(buttonContainer.snp.bottom)
            make.width.greaterThanOrEqualTo(80)
        }
    }
    
    private func setAccessibilityIdentifiers() {
        bannerLabel.accessibilityIdentifier = "CourseResetDateView:banner-text-label"
        bannerButton.accessibilityIdentifier = "CourseResetDateView:reset-date-button"
    }
    
    func heightForView(text: String, width: CGFloat) -> CGFloat {
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: width, height: maxHeight))
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.font = bannerStyle.fontFromStyle()
        label.text = text

        label.sizeToFit()
        
        return label.frame.height
    }
}


fileprivate extension UIView {
    func configure(backgroundColor: UIColor, borderColor: UIColor , borderWith: CGFloat, cornerRadius: CGFloat) {
        layer.backgroundColor = backgroundColor.cgColor
        layer.borderWidth = borderWith
        layer.borderColor = borderColor.cgColor
        layer.cornerRadius = cornerRadius
    }
}
