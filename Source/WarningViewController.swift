//
//  WarningViewController.swift
//  edX
//
//  Created by Saeed Bashir on 6/1/16.
//  Copyright © 2016 edX. All rights reserved.
//

private let HeaderHeight : CGFloat = 30.0

class WarningViewController: UIViewController {
    
    enum WarningType {
        case OfflineMode
        case VersionUpgrade
    }
 
    // View to show warning info
    private let headerView: UIView = UIView()
    // View to show screen content
    let contentView: UIView = UIView()
    private let bottomDivider : UIView = UIView(frame: CGRectZero)
    private let infoLabel: UILabel = UILabel(frame: CGRectZero)
    private let infoButton: UIButton = UIButton(type: .System)
    private var isActive:Bool = false
    private var warningType: WarningType?
    private var infoLabelStyle : OEXTextStyle {
        return OEXTextStyle(weight: .SemiBold, size: .XXSmall, color: OEXStyles.sharedStyles().neutralDark())
    }
    
    private var infoButtonStyle : OEXTextStyle {
        return OEXTextStyle(weight: .Light, size: .XLarge, color: OEXStyles.sharedStyles().neutralDark())
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    private func setup() {
        addSubviews()
        setStyles()
        addConstraints()
        configureInfoButton()
        addOfflineObserver()
    }
    
    private func setStyles() {
        headerView.backgroundColor = OEXStyles.sharedStyles().warningBase()
        bottomDivider.backgroundColor = OEXStyles.sharedStyles().warningBase()
        contentView.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
    }
    
    private func configureInfoButton() {
        let infoIcon = Icon.MoreInfo.attributedTextWithStyle(infoButtonStyle)
        
        infoButton.setAttributedTitle(NSAttributedString.joinInNaturalLayout([infoIcon]), forState: .Normal)
        
        infoButton.oex_removeAllActions()
        infoButton.oex_addAction({[weak self] _ in
            self?.showOverlayMessage()
            }, forEvents: .TouchUpInside)
    }
    
    private func showOverlayMessage() {
        var title: String?
        var detail: String?
        switch warningType ?? .OfflineMode {
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
        
        if case .VersionUpgrade = self.warningType ?? .OfflineMode {
            overlayView.buttonInfo = MessageButtonInfo(title: "Tap Here To Upgrade Now", action: {
                UIApplication.sharedApplication().openURL(OEXConfig.sharedConfig().appStoreURL())
            })
        }
        
        self.showOverlayMessageView(overlayView)
    }
    
    private func addSubviews() {
        view.addSubview(headerView)
        view.addSubview(contentView)
        
        headerView.addSubview(infoLabel)
        headerView.addSubview(infoButton)
        headerView.addSubview(bottomDivider)
    }
    
    private func addConstraints() {
        headerView.snp_makeConstraints { (make) in
            make.top.equalTo(view)
            make.trailing.equalTo(view)
            make.leading.equalTo(view)
            make.height.equalTo(0)
        }
        
        contentView.snp_makeConstraints { (make) in
            make.top.equalTo(headerView.snp_bottom)
            make.trailing.equalTo(view)
            make.leading.equalTo(view)
            make.bottom.equalTo(view)
        }
        
        bottomDivider.snp_makeConstraints {make in
            make.bottom.equalTo(headerView)
            make.height.equalTo(OEXStyles.dividerSize())
            make.leading.equalTo(headerView)
            make.trailing.equalTo(headerView)
        }
        
        infoLabel.snp_makeConstraints {make in
            make.top.equalTo(headerView).offset(StandardVerticalMargin)
            make.bottom.equalTo(headerView).offset(-StandardVerticalMargin)
            make.leading.equalTo(headerView).offset(StandardHorizontalMargin)
            make.trailing.lessThanOrEqualTo(infoButton).offset(-StandardHorizontalMargin)
        }
        
        infoButton.snp_makeConstraints { (make) in
            make.centerY.equalTo(headerView)
            make.trailing.equalTo(headerView).offset(-StandardHorizontalMargin)
        }
    }
    
    private func addOfflineObserver() {
        NSNotificationCenter.defaultCenter().oex_addObserver(self, name: kReachabilityChangedNotification) { (notification, observer, _) in
            observer.updateOfflineHeader()
        }
    }
    
    private func updateOfflineHeader() {
        if !OEXRouter.sharedRouter().environment.reachability.isReachable() {
            isActive = true
            infoLabel.attributedText = infoLabelStyle.attributedStringWithText(Strings.offlineMode)
        }
        else {
            isActive = false
        }
        
        warningType = .OfflineMode
        view.setNeedsUpdateConstraints()
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        
        headerView.snp_remakeConstraints { (make) in
            make.top.equalTo(view)
            make.trailing.equalTo(view)
            make.leading.equalTo(view)
            make.height.equalTo(isActive ? HeaderHeight : 0)
        }
        
        contentView.snp_remakeConstraints { (make) in
            make.top.equalTo(headerView.snp_bottom)
            make.trailing.equalTo(view)
            make.leading.equalTo(view)
            make.bottom.equalTo(view)
        }
    }
}