//
//  WhatsNewContentController.swift
//  edX
//
//  Created by Saeed Bashir on 5/4/17.
//  Copyright © 2017 edX. All rights reserved.
//

import Foundation

private let ScreenDivider: CGFloat = 1.65
private let LeftRightMargin: CGFloat = 25

class WhatsNewContentController: UIViewController {
    private let containerView = UIView()
    private let imageContainer = UIView()
    private let infoContainer = UIView()
    private let gradientLayer = CAGradientLayer()
    private let screenImageView = UIImageView()
    private let titleLabel = UILabel()
    private let messageLabel = UILabel()
    
    private var titleStyle : OEXTextStyle {
        return OEXTextStyle(weight: .semiBold, size: .xLarge, color: OEXStyles.shared().neutralWhite())
    }
    
    private var messageStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .xLarge, color: OEXStyles.shared().neutralWhite())
    }
    
    typealias Environment = OEXStylesProvider
    private let environment : Environment
    var whatsNew: WhatsNew? {
        didSet{
            popupateView()
        }
    }
    
    init(environment: Environment) {
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setConstraints()
        applyGradient()
    }
    
    private func configureViews() {
        containerView.accessibilityIdentifier = "WhatsNewContentController:container-view"
        imageContainer.accessibilityIdentifier = "WhatsNewContentController:image-container-view"
        infoContainer.accessibilityIdentifier = "WhatsNewContentController:info-container-view"
        screenImageView.accessibilityIdentifier = "WhatsNewContentController:screen-image-view"
        titleLabel.accessibilityIdentifier = "WhatsNewContentController:title-label"
        messageLabel.accessibilityIdentifier = "WhatsNewContentController:message-label"
        
        containerView.backgroundColor = environment.styles.primaryBaseColor()
        screenImageView.contentMode = .scaleAspectFit
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontSizeToFitWidth = true
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.adjustsFontSizeToFitWidth = true
        
        view.addSubview(containerView)
        containerView.addSubview(imageContainer)
        containerView.addSubview(infoContainer)
        
        imageContainer.addSubview(screenImageView)
        infoContainer.addSubview(titleLabel)
        infoContainer.addSubview(messageLabel)
    }
    
    private func applyGradient() {
        gradientLayer.colors = [environment.styles.primaryDarkColor().cgColor, environment.styles.primaryBaseColor().cgColor]
        gradientLayer.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height/ScreenDivider )
        gradientLayer.startPoint = CGPoint(x: 0, y: 1)
        gradientLayer.endPoint = CGPoint(x: 0, y: 0)
        imageContainer.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    private func setConstraints() {
        
        containerView.snp.remakeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
        
        imageContainer.snp.remakeConstraints { make in
            make.top.equalTo(containerView)
            make.trailing.equalTo(containerView)
            make.leading.equalTo(containerView)
            let height = view.bounds.size.height / ScreenDivider
            make.height.equalTo(height)
        }
        
        infoContainer.snp.remakeConstraints { make in
            make.top.equalTo(imageContainer.snp.bottom)
            make.trailing.equalTo(containerView)
            make.leading.equalTo(containerView)
            make.bottom.equalTo(containerView)
        }
        
        screenImageView.snp.remakeConstraints { make in
            make.top.equalTo(imageContainer).offset(2*StandardVerticalMargin)
            make.bottom.equalTo(imageContainer)
            make.trailing.equalTo(imageContainer).offset(-LeftRightMargin)
            make.leading.equalTo(imageContainer).offset(LeftRightMargin)
        }
        
        titleLabel.snp.remakeConstraints { make in
            make.top.equalTo(infoContainer).offset(2*StandardVerticalMargin)
            make.centerX.equalTo(infoContainer)
            make.trailing.lessThanOrEqualTo(infoContainer).offset(-LeftRightMargin)
            make.leading.lessThanOrEqualTo(infoContainer).offset(LeftRightMargin)
        }
        
        messageLabel.snp.remakeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(StandardVerticalMargin)
            make.bottom.lessThanOrEqualTo(infoContainer).offset(-StandardVerticalMargin)
            make.centerX.equalTo(infoContainer)
            make.trailing.lessThanOrEqualTo(infoContainer).offset(-LeftRightMargin)
            make.leading.lessThanOrEqualTo(infoContainer).offset(LeftRightMargin)
        }
    }
    
    private func popupateView() {
        titleLabel.attributedText = titleStyle.attributedString(withText: whatsNew?.title)
        messageLabel.attributedText = messageStyle.attributedString(withText: whatsNew?.message)
        screenImageView.image = whatsNew?.image
    }
    
}
