//
//  SnackbarViews.swift
//  edX
//
//  Created by Saeed Bashir on 7/15/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation
private let animationDuration: TimeInterval = 1.0

public class VersionUpgradeView: UIView {
    private let messageLabel = UILabel()
    private let upgradeButton = UIButton(type: .system)
    private let dismissButton = UIButton(type: .system)
    private var messageLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().neutralDark())
    }
    
    private var buttonLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .semiBold, size: .base, color: OEXStyles.shared().neutralDark())
    }
    
    init(message: String) {
        super.init(frame: CGRect.zero)
        self.backgroundColor = OEXStyles.shared().warningBase()
        messageLabel.numberOfLines = 0
        messageLabel.attributedText = messageLabelStyle.attributedString(withText: message)
        upgradeButton.setAttributedTitle(buttonLabelStyle.attributedString(withText: Strings.versionUpgradeUpdate), for: .normal)
        dismissButton.setAttributedTitle(buttonLabelStyle.attributedString(withText: Strings.VersionUpgrade.dismiss), for: .normal)
        
        addSubview(messageLabel)
        addSubview(dismissButton)
        addSubview(upgradeButton)
        
        addConstraints()
        addButtonActions()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addConstraints() {
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(self).offset(StandardVerticalMargin)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.trailing.equalTo(self).offset(-StandardHorizontalMargin)
        }
        
        upgradeButton.snp.makeConstraints { make in
            make.top.equalTo(messageLabel.snp.bottom)
            make.trailing.equalTo(self).offset(-StandardHorizontalMargin)
            make.bottom.equalTo(self).offset(-StandardVerticalMargin)
        }
        
        dismissButton.snp.makeConstraints { make in
            make.top.equalTo(messageLabel.snp.bottom)
            make.trailing.equalTo(upgradeButton.snp.leading).offset(-StandardHorizontalMargin)
            make.bottom.equalTo(self).offset(-StandardVerticalMargin)
        }
    }
    
    private func addButtonActions() {
        dismissButton.oex_addAction({[weak self] _ in
            self?.dismissView()
            }, for: .touchUpInside)
        
        upgradeButton.oex_addAction({[weak self]  _ in
            if let URL = OEXConfig.shared().appUpgradeConfig.iOSAppStoreURL() {
                if UIApplication.shared.canOpenURL(URL as URL) {
                    self?.dismissView()
                    UIApplication.shared.openURL(URL as URL)
                    isActionTakenOnUpgradeSnackBar = true
                }
            }
            }, for: .touchUpInside)
    }
    
    private func dismissView() {
        var container = superview
        if container == nil {
            container = self
        }
        
        UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.1, options: .curveEaseOut, animations: {
            self.transform = .identity
            }, completion: { _ in
                container?.removeFromSuperview()
                isActionTakenOnUpgradeSnackBar = true
        })
    }
}

public class OfflineView: UIView {
    private let messageLabel = UILabel()
    private let reloadButton = UIButton(type: .system)
    private let dismissButton = UIButton(type: .system)
    private var selector: Selector?
    private var messageLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().neutralDark())
    }
    
    private var buttonLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .semiBold, size: .base, color: OEXStyles.shared().neutralDark())
    }
    
    init(message: String, selector: Selector?) {
        super.init(frame: CGRect.zero)
        self.selector = selector
        self.backgroundColor = OEXStyles.shared().warningBase()
        messageLabel.numberOfLines = 0
        messageLabel.attributedText = messageLabelStyle.attributedString(withText: message)
        reloadButton.setAttributedTitle(buttonLabelStyle.attributedString(withText: Strings.reload), for: .normal)
        dismissButton.setAttributedTitle(buttonLabelStyle.attributedString(withText: Strings.VersionUpgrade.dismiss), for: .normal)
        addSubview(messageLabel)
        addSubview(dismissButton)
        addSubview(reloadButton)
        
        addConstraints()
        addButtonActions()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    private func addConstraints() {
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(self).offset(StandardVerticalMargin)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.trailing.lessThanOrEqualTo(dismissButton).offset(-StandardHorizontalMargin)
            make.centerY.equalTo(reloadButton)
        }
        
        reloadButton.snp.makeConstraints { make in
            make.top.equalTo(messageLabel)
            make.trailing.equalTo(self).offset(-StandardHorizontalMargin)
            make.bottom.equalTo(self).offset(-StandardVerticalMargin)
        }
        
        dismissButton.snp.makeConstraints { make in
            make.top.equalTo(reloadButton)
            make.trailing.equalTo(reloadButton.snp.leading).offset(-StandardHorizontalMargin)
            make.bottom.equalTo(self).offset(-StandardVerticalMargin)
        }
    }
    
    private func addButtonActions() {
        dismissButton.oex_addAction({[weak self] _ in
            self?.dismissView()
            }, for: .touchUpInside)
        
        reloadButton.oex_addAction({[weak self] _ in
            let controller = self?.firstAvailableUIViewController()
            if let controller = controller, let selector = self?.selector {
                if controller.responds(to: selector) && OEXRouter.shared().environment.reachability.isReachable() {
                    controller.perform(selector)
                    self?.dismissView()
                }
            }
            else {
                self?.dismissView()
            }
            }, for: .touchUpInside)
    }
    
    private func dismissView() {
        var container = superview
        if container == nil {
            container = self
        }
        
        UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.1, options: .curveEaseOut, animations: {
            self.transform = .identity
            }, completion: { _ in
                container!.removeFromSuperview()
        })
    }
}

public class DateResetToastView: UIView {
    
    private lazy var container = UIView()
    private lazy var buttonContainer = UIView()
    
    private lazy var stackView: TZStackView = {
        let stackView = TZStackView()
        stackView.spacing = StandardHorizontalMargin / 4
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.axis = .vertical
        
        return stackView
    }()
    
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        
        return label
    }()
    
    private lazy var button: UIButton = {
        let button = UIButton()
        button.layer.cornerRadius = 10
        button.layer.borderWidth = 1
        button.layer.borderColor = OEXStyles.shared().neutralWhite().cgColor
        
        return button
    }()
    
    private lazy var dismissButton: UIButton = {
        let button = UIButton()
        button.setImage(lockImage, for: UIControl.State())
        button.tintColor = OEXStyles.shared().neutralWhite()
        
        return button
    }()
        
    private lazy var messageLabelStyle: OEXTextStyle = {
        return OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().neutralWhite())
    }()
    
    private lazy var buttonStyle: OEXTextStyle = {
        return OEXTextStyle(weight: .normal, size: .small, color: OEXStyles.shared().neutralWhite())
    }()
    
    private lazy var buttonLabelStyle: OEXTextStyle = {
        return OEXTextStyle(weight: .semiBold, size: .base, color: OEXStyles.shared().neutralWhite())
    }()
    
    private lazy var lockImage: UIImage = {
        return Icon.Close.imageWithFontSize(size: 14).withRenderingMode(.alwaysTemplate)
    }()
    
    init(message: String, buttonText: String? = nil, showButton: Bool = false, buttonAction: (()->())? = nil) {
        super.init(frame: CGRect.zero)
        
        self.backgroundColor = OEXStyles.shared().neutralXDark()
                        
        messageLabel.attributedText = messageLabelStyle.attributedString(withText: message)
        messageLabel.sizeToFit()
        
        stackView.addArrangedSubview(messageLabel)

        if showButton {
            button.oex_addAction({ _ in
                buttonAction?()
            }, for: .touchUpInside)
            button.setAttributedTitle(buttonStyle.attributedString(withText: buttonText), for: UIControl.State())
            buttonContainer.addSubview(button)
            stackView.addArrangedSubview(buttonContainer)
        }
        
        container.addSubview(stackView)
        container.addSubview(dismissButton)
        
        addSubview(container)
        
        addConstraints(showButton: showButton)
        addButtonActions()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addConstraints(showButton: Bool) {
        stackView.snp.makeConstraints { make in
            make.leading.equalTo(container).inset(StandardVerticalMargin * 2)
            make.trailing.equalTo(dismissButton.snp.leading)
            make.top.equalTo(container).offset(StandardVerticalMargin)
            make.bottom.equalTo(container).inset(StandardVerticalMargin)
        }
        
        container.snp.makeConstraints { make in
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
            make.top.equalTo(self)
            make.bottom.equalTo(self)
            make.height.greaterThanOrEqualTo(StandardHorizontalMargin * 6)
        }
        
        dismissButton.snp.makeConstraints { make in
            make.trailing.equalTo(self).inset(StandardVerticalMargin)
            make.top.equalTo(self).inset(StandardVerticalMargin)
            make.width.equalTo(StandardHorizontalMargin * 2)
            make.height.equalTo(StandardHorizontalMargin * 2)
        }
        
        if showButton {
            buttonContainer.snp.makeConstraints { make in
                make.leading.equalTo(stackView.snp.leading)
                make.trailing.equalTo(stackView.snp.trailing)
            }
            
            button.snp.makeConstraints { make in
                make.trailing.equalTo(buttonContainer.snp.trailing)
                make.top.equalTo(buttonContainer.snp.top)
                make.bottom.equalTo(buttonContainer.snp.bottom)
                make.width.greaterThanOrEqualTo(StandardHorizontalMargin * 7)
            }
        }
    }
    
    private func addButtonActions() {
        dismissButton.oex_addAction({ [weak self] _ in
            self?.dismissView()
        }, for: .touchUpInside)
    }
    
    private func dismissView() {
        var container = superview
        if container == nil {
            container = self
        }
        
        UIView.animate(withDuration: animationDuration, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 0.1, options: .curveEaseOut, animations: { [weak self] in
            self?.transform = .identity
        }) { _ in
            container?.removeFromSuperview()
        }
    }
}
