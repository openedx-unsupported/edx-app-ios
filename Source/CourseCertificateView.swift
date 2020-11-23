//
//  CourseCertificateView.swift
//  edX
//
//  Created by Salman on 05/01/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

struct CourseCertificateIem {
    let certificateImage: UIImage
    let certificateUrl: String
    let action:(() -> Void)?
}

class CourseCertificateView: UIView {
    
    static let height: CGFloat = 100.0
    private let certificateImageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private lazy var viewCertificateButton: UIButton = {
        let button = UIButton()
        button.isUserInteractionEnabled = false
        button.applyButtonStyle(style: OEXStyles.shared().filledPrimaryButtonStyle, withTitle: Strings.Certificates.getCertificate)
        return button
    }()
    
    var certificateItem : CourseCertificateIem? {
        didSet {
            useItem(item: certificateItem)
        }
    }
    
    init() {
        super.init(frame: CGRect.zero)
        configureViews()
    }
    
    convenience init(certificateItem: CourseCertificateIem) {
        self.init()
        self.certificateItem = certificateItem
        useItem(item: certificateItem)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureViews() {
        backgroundColor =  OEXStyles.shared().neutralXLight()
        
        addSubview(certificateImageView)
        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(viewCertificateButton)
        
        certificateImageView.contentMode = .scaleAspectFit
        certificateImageView.setContentCompressionResistancePriority(UILayoutPriority.required, for: .horizontal)
        
        titleLabel.setContentCompressionResistancePriority(UILayoutPriority.defaultLow, for: .horizontal)
        subtitleLabel.adjustsFontSizeToFitWidth = true
        
        certificateImageView.snp.makeConstraints { make in
            make.top.equalTo(self).offset(StandardVerticalMargin)
            make.bottom.equalTo(self).inset(StandardVerticalMargin)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(certificateImageView)
            make.trailing.equalTo(self).inset(StandardHorizontalMargin)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom)
        }
        
        viewCertificateButton.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(titleLabel)
            make.bottom.equalTo(certificateImageView)
        }

        setAccessibilityIdentifiers()
    }

    private func setAccessibilityIdentifiers() {
        accessibilityIdentifier = "CourseCertificateView:view"
        certificateImageView.accessibilityIdentifier = "CourseCertificateView:certificate-image-view"
        titleLabel.accessibilityIdentifier = "CourseCertificateView:title-label"
        subtitleLabel.accessibilityIdentifier = "CourseCertificateView:subtitle-label"
        viewCertificateButton.accessibilityIdentifier = "CourseCertificateView:view-certificate-button"
    }
    
    private func useItem(item: CourseCertificateIem?) {
        guard let certificateItem = item else {return}
        certificateImageView.image = certificateItem.certificateImage
        
        let titleStyle = OEXTextStyle(weight: .normal, size: .large, color: OEXStyles.shared().primaryBaseColor())
        let subtitleStyle = OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().primaryXLightColor())
        
        titleLabel.attributedText = titleStyle.attributedString(withText: Strings.Certificates.courseCompletionTitle)
        subtitleLabel.attributedText = subtitleStyle.attributedString(withText: Strings.Certificates.courseCompletionSubtitle)
        
        addActionIfNeccessary()
    }
    
    private func addActionIfNeccessary() {
        guard let item = certificateItem,
            let action = item.action else { return }
        
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addAction { _ in
            action()
        }
        addGestureRecognizer(tapGesture)
    }
    
}


