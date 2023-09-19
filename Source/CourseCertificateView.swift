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
    
    static let height: CGFloat = 132.0
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

        setAccessibilityIdentifiers()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setConstraints()
    }
    
    private func setConstraints() {
        if traitCollection.verticalSizeClass == .regular {
            addPortraitConstraints()
        } else {
            addLandscapeConstraints()
        }
    }
    
    private func addPortraitConstraints() {
        if OEXConfig.shared().isNewDashboardEnabled {
            certificateImageView.snp.remakeConstraints { make in
                make.top.equalTo(self).offset(StandardVerticalMargin * 2)
                make.centerX.equalTo(self)
                make.width.equalTo(138)
                make.height.equalTo(100)
            }
            
            titleLabel.snp.remakeConstraints { make in
                make.top.equalTo(certificateImageView.snp.bottom).offset(StandardVerticalMargin * 2)
                make.centerX.equalTo(certificateImageView)
            }
            
            subtitleLabel.snp.remakeConstraints { make in
                make.top.equalTo(titleLabel.snp.bottom).offset(StandardVerticalMargin)
                make.centerX.equalTo(titleLabel)
            }
            
            viewCertificateButton.snp.remakeConstraints { make in
                make.top.equalTo(subtitleLabel.snp.bottom).offset(StandardVerticalMargin * 2)
                make.leading.equalTo(self).offset(StandardHorizontalMargin)
                make.trailing.equalTo(self).inset(StandardHorizontalMargin)
                make.centerX.equalTo(subtitleLabel)
                make.height.equalTo(StandardVerticalMargin * 4.5)
                make.bottom.equalTo(self).inset(StandardVerticalMargin * 2)
                
            }
        }
        else {
            // old portrait style is somewhat close to landscape design so for view simplicity using that here as well
            addLandscapeConstraints()
        }
    }
    
    private func addLandscapeConstraints() {
        certificateImageView.snp.remakeConstraints { make in
            make.top.equalTo(self).offset(StandardVerticalMargin * 2)
            make.bottom.equalTo(self).inset(StandardVerticalMargin * 2)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.width.equalTo(138)
            make.height.equalTo(100)
        }
        
        titleLabel.snp.remakeConstraints { make in
            make.top.equalTo(certificateImageView)
            make.leading.equalTo(certificateImageView.snp.trailing).offset(StandardHorizontalMargin)
            make.trailing.equalTo(self).inset(StandardHorizontalMargin)
        }
        
        subtitleLabel.snp.remakeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(StandardVerticalMargin)
            make.leading.equalTo(titleLabel)
            make.trailing.equalTo(titleLabel)
        }
        
        viewCertificateButton.snp.remakeConstraints { make in
            make.leading.equalTo(subtitleLabel)
            make.trailing.equalTo(self).inset(StandardHorizontalMargin)
            make.height.equalTo(StandardVerticalMargin * 4.5)
            make.bottom.equalTo(certificateImageView)
        }
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
        
        let titleStyle = OEXMutableTextStyle(weight: .normal, size: .large, color: OEXStyles.shared().primaryBaseColor())
        let subtitleStyle = OEXMutableTextStyle(weight: .normal, size: .small, color: OEXStyles.shared().primaryXLightColor())
        
        var title = Strings.Certificates.courseCompletionTitle
        if OEXConfig.shared().isNewDashboardEnabled {
            titleStyle.weight = .bold
            titleStyle.size = .xxLarge
            titleStyle.color = OEXStyles.shared().neutralBlack()
            subtitleStyle.color = OEXStyles.shared().neutralXDark()
            title = title.capitalized
        }
        
        titleLabel.attributedText = titleStyle.attributedString(withText: title)
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
