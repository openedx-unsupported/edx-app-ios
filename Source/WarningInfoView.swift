//
//  WarningInfoView.swift
//  edX
//
//  Created by Akiva Leffert on 5/15/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public class WarningInfoView: UIView {
    
    public enum WarningType {
        case OfflineMode
        case VersionUpgrade
    }
    
    private let verticalMargin = StandardVerticalMargin
    private let bottomDivider : UIView = UIView(frame: CGRectZero)
    private let messageView : UILabel = UILabel(frame: CGRectZero)
    private let infoButton: UIButton = UIButton(type: .System)
    private let warningType : WarningType
    private weak var viewController:UIViewController?
    private var textColor : UIColor? {
        return OEXStyles.sharedStyles().neutralDark()
    }
    
    private var backgroudColor: UIColor? {
        return OEXStyles.sharedStyles().warningBase()
    }
    
    required public init(frame: CGRect, warningType: WarningType, viewController: UIViewController?) {
        
        self.warningType = warningType
        self.viewController = viewController
        super.init(frame: frame)
        
        addSubview(bottomDivider)
        addSubview(messageView)
        addSubview(infoButton)
        
        backgroundColor = backgroudColor
        bottomDivider.backgroundColor = backgroudColor
        
        messageView.attributedText = warningTitle()
        
        let infoIcon = Icon.MoreInfo.attributedTextWithStyle(infoButtonStyle)
        
        infoButton.setAttributedTitle(NSAttributedString.joinInNaturalLayout([infoIcon]), forState: .Normal)
        
        infoButton.oex_removeAllActions()
        infoButton.oex_addAction({[weak self] _ in
            self?.showOverlayMessage()
            }, forEvents: .TouchUpInside)
        
        addConstraints()
    }

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private var labelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .SemiBold, size: .XXSmall, color: textColor)
    }
    
    private var infoButtonStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Light, size: .XLarge, color: textColor)
    }
    
    private func addConstraints() {
        bottomDivider.snp_makeConstraints {make in
            make.bottom.equalTo(self)
            make.height.equalTo(OEXStyles.dividerSize())
            make.leading.equalTo(self)
            make.trailing.equalTo(self)
        }
        
        messageView.snp_makeConstraints {make in
            make.top.equalTo(self).offset(verticalMargin)
            make.bottom.equalTo(self).offset(-verticalMargin)
            make.leading.equalTo(self).offset(StandardHorizontalMargin)
            make.trailing.lessThanOrEqualTo(infoButton).offset(-StandardHorizontalMargin)
        }
        
        infoButton.snp_makeConstraints { (make) in
            make.centerY.equalTo(self)
            make.trailing.equalTo(self).offset(-StandardHorizontalMargin)
        }
    }
    
    private func warningTitle() -> NSAttributedString {
        switch warningType {
        case .OfflineMode:
            return labelStyle.attributedStringWithText(Strings.offlineMode)
        case .VersionUpgrade:
            return labelStyle.attributedStringWithText(Strings.VersionUpgrade.upgrade)
        }
    }
    
    private func showOverlayMessage() {
        
        var title: String?
        var detail: String?
        
        switch warningType {
        case .OfflineMode:
            title = Strings.offlineMode
            detail = Strings.offlineModeDetail
            
        case .VersionUpgrade:
            detail = Strings.VersionUpgrade.upgradeDetailMessage(platformName: OEXConfig.sharedConfig().platformName())
            if let lastSupportedDate = VersionUpgradeInfoController.sharedController.lastSupportedDateString {
                detail = Strings.VersionUpgrade.upgradeLastSupportedDateOverlayMessgae(platformName: OEXConfig.sharedConfig().platformName(), date: lastSupportedDate)
            }
        }
        
        let overlayView = WarningInfoOverlay(title: title, detail: detail)
        
        if case .VersionUpgrade = self.warningType {
            overlayView.buttonInfo = MessageButtonInfo(title: "Tap Here To Upgrade Now", action: {
                UIApplication.sharedApplication().openURL(OEXConfig.sharedConfig().appStoreURL())
            })
        }
        
        if let viewController = viewController {
            viewController.showOverlayMessageView(overlayView)
        }
    }
}
