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
