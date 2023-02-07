//
//  ProfileOptionsViewController.swift
//  edX
//
//  Created by Muhammad Umer on 27/07/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import UIKit
import MessageUI

fileprivate let titleTextStyle = OEXMutableTextStyle(weight: .secondaryNormal, size: .small, color: OEXStyles.shared().neutralXDark())
fileprivate let textStyle = OEXMutableTextStyle(weight: .normal, size: .small, color: OEXStyles.shared().neutralXDark())
fileprivate let subtitleTextStyle = OEXMutableTextStyle(weight: .bold, size: .base, color: OEXStyles.shared().primaryDarkColor())
fileprivate let imageSize: CGFloat = 36

class ProfileOptionsViewController: UIViewController {
    
    private enum ProfileOptions {
        case videoSetting
        case personalInformation
        case restorePurchase
        case privacy
        case help(Bool, Bool)
        case signout
        case deleteAccount
    }
    
    typealias Environment = OEXStylesProvider & OEXConfigProvider & NetworkManagerProvider & DataManagerProvider & OEXRouterProvider & OEXSessionProvider & OEXInterfaceProvider & OEXAnalyticsProvider & ServerConfigProvider
    
    let environment: Environment
    
    private let crossButtonSize: CGFloat = 20
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.tableFooterView = UIView()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorInset = .zero
        tableView.alwaysBounceVertical = false
        tableView.register(VideoSettingCell.self, forCellReuseIdentifier: VideoSettingCell.identifier)
        tableView.register(PersonalInformationCell.self, forCellReuseIdentifier: PersonalInformationCell.identifier)
        tableView.register(RestorePurchasesCell.self, forCellReuseIdentifier: RestorePurchasesCell.identifier)
        tableView.register(PrivacyCell.self, forCellReuseIdentifier: PrivacyCell.identifier)
        tableView.register(HelpCell.self, forCellReuseIdentifier: HelpCell.identifier)
        tableView.register(SignOutVersionCell.self, forCellReuseIdentifier: SignOutVersionCell.identifier)
        tableView.register(DeleteAccountCell.self, forCellReuseIdentifier: DeleteAccountCell.identifier)
        tableView.accessibilityIdentifier = "ProfileOptionsViewController:table-view"
        
        return tableView
    }()
    
    private var options: [ProfileOptions] = []
    private var userProfile: UserProfile? {
        didSet {
            for cell in tableView.visibleCells where cell is PersonalInformationCell {
                if let indexPath = tableView.indexPath(for: cell) {
                    tableView.reloadRows(at: [indexPath], with: .none)
                }
            }
        }
    }

    private var isModalDismissable: Bool = true
    
    init(environment: Environment) {
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = Strings.UserAccount.profile
                
        setupViews()
        addCloseButton()
        configureOptions()
        setupProfileLoader()
        
        navigationController?.view.backgroundColor = environment.styles.standardBackgroundColor()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        environment.analytics.trackScreen(withName: AnalyticsScreenName.Profile.rawValue)
        setupProfileLoader()
        navigationController?.navigationBar.prefersLargeTitles = true
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        navigationController?.navigationBar.prefersLargeTitles = false
    }
    
    private func setupViews() {
        view.backgroundColor = environment.styles.standardBackgroundColor()
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
    }
    
    private func setupProfileLoader() {
        guard environment.config.profilesEnabled else { return }
        let profileFeed = environment.dataManager.userProfileManager.feedForCurrentUser()
        
        if let profile = profileFeed.output.value {
            userProfile = profile
        } else {
            profileFeed.output.listen(self,  success: { [weak self] profile in
                self?.userProfile = profile
            }, failure : { _ in
                Logger.logError("Profiles", "Unable to fetch profile")
            })
            profileFeed.refresh()
        }
    }

    private func addCloseButton() {
        let closeButton = UIBarButtonItem(image: Icon.Close.imageWithFontSize(size: crossButtonSize), style: .plain, target: nil, action: nil)
        closeButton.accessibilityLabel = Strings.Accessibility.closeLabel
        closeButton.accessibilityHint = Strings.Accessibility.closeHint
        closeButton.accessibilityIdentifier = "ProfileOptionsViewController:close-button"
        navigationItem.rightBarButtonItem = closeButton

        closeButton.oex_setAction { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }

    private func configureOptions() {
        options.append(.videoSetting)
        
        if environment.config.profilesEnabled {
            options.append(.personalInformation)
        }
        
        if environment.serverConfig.iapConfig?.enabled ?? false {
            options.append(.restorePurchase)
        }
        
        if environment.config.agreementURLsConfig.enabledForProfile {
            options.append(.privacy)
        }
        
        let feedbackEnabled =  environment.config.feedbackEmailAddress() != nil
        let faqEnabled = environment.config.faqURL != nil
        
        if feedbackEnabled || faqEnabled {
            options.append(.help(feedbackEnabled, faqEnabled))
        }
        
        options.append(.signout)

        if environment.config.deleteAccountURL != nil {
            options.append(.deleteAccount)
        }
        
        tableView.reloadData()
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension ProfileOptionsViewController: MFMailComposeViewControllerDelegate {
    func launchEmailComposer() {
        if !MFMailComposeViewController.canSendMail() {
            UIAlertController().showAlert(withTitle: Strings.emailAccountNotSetUpTitle, message: Strings.emailAccountNotSetUpMessage, onViewController: self)
        } else {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.navigationBar.tintColor = OEXStyles.shared().navigationItemTintColor()
            mail.setSubject(Strings.SubmitFeedback.messageSubject)
            
            mail.setMessageBody(EmailTemplates.supportEmailMessageTemplate(), isHTML: false)
            if let fbAddress = environment.config.feedbackEmailAddress() {
                mail.setToRecipients([fbAddress])
            }
            present(mail, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        dismiss(animated: true, completion: nil)
    }
}

extension ProfileOptionsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: .zero)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch options[indexPath.row] {
        case .videoSetting:
            return wifiCell(tableView, indexPath: indexPath)
            
        case .personalInformation:
            return personalInformationCell(tableView, indexPath: indexPath)
        
        case .restorePurchase:
            return restorePurchaseCell(tableView, indexPath: indexPath)
            
        case .privacy:
            return privacyCell(tableView, indexPath: indexPath)
            
        case .help(let feedbackEnabled, let faqEnabled):
            return helpCell(tableView, indexPath: indexPath, feedbackEnabled: feedbackEnabled, faqEnabled: faqEnabled)
            
        case .signout:
            return signoutCell(tableView, indexPath: indexPath)
        case .deleteAccount:
            return deleteAccountCell(tableView, indexPath: indexPath)
        }
    }
    
    private func wifiCell(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: VideoSettingCell.identifier, for: indexPath) as! VideoSettingCell
        cell.delegate = self
        cell.wifiSwitch.isOn = environment.interface?.shouldDownloadOnlyOnWifi ?? false
        cell.updateVideoDownloadQualityLabel()
        return cell
    }
    
    private func personalInformationCell(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PersonalInformationCell.identifier, for: indexPath) as! PersonalInformationCell
        
        guard environment.config.profilesEnabled,
              let username = environment.session.currentUser?.username,
              let email = environment.session.currentUser?.email else { return cell }
        
        if let userProfile = userProfile {
            cell.profileSubtitle = (userProfile.sharingLimitedProfile && userProfile.parentalConsent == false) ? Strings.ProfileOptions.UserProfile.message : nil
            cell.profileImageView.remoteImage = userProfile.image(networkManager: environment.networkManager)
        }
        
        cell.update(username: username, email: email)
        
        return cell
    }
    
    private func restorePurchaseCell(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: RestorePurchasesCell.identifier, for: indexPath) as! RestorePurchasesCell
        cell.delegate = self

        return cell
    }
    
    private func privacyCell(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PrivacyCell.identifier, for: indexPath) as! PrivacyCell
        cell.delegate = self
        let config = environment.config.agreementURLsConfig
        let privacyEnabled = !(config.privacyPolicyURL?.absoluteString.isEmpty ?? true)
        let cookieEnabled = !(config.cookiePolicyURL?.absoluteString.isEmpty ?? true)
        let dataSellConsentEnabled = !(config.dataSellConsentURL?.absoluteString.isEmpty ?? true)
        cell.configure(privacyEnabled: privacyEnabled, cookieEnabled: cookieEnabled, dataSellConsentEnabled: dataSellConsentEnabled)
        
        return cell
    }

    private func helpCell(_ tableView: UITableView, indexPath: IndexPath, feedbackEnabled: Bool, faqEnabled: Bool) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HelpCell.identifier, for: indexPath) as! HelpCell
        cell.delegate = self
        cell.update(feedbackEnabled: feedbackEnabled, faqEnabled: faqEnabled, platformName: environment.config.platformName())
        
        return cell
    }

    private func signoutCell(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SignOutVersionCell.identifier, for: indexPath) as! SignOutVersionCell
        cell.delegate = self
        return cell
    }

    private func deleteAccountCell(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DeleteAccountCell.identifier, for: indexPath) as! DeleteAccountCell
        cell.delegate = self
        return cell
    }
}

extension ProfileOptionsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch options[indexPath.row] {
        case .personalInformation:
            guard environment.config.profilesEnabled, let username = environment.session.currentUser?.username else { return }
            environment.router?.showProfileForUsername(controller: self, username: username, editable: true)
            environment.analytics.trackProfileOptionClcikEvent(displayName: AnalyticsDisplayName.PersonalInformationClicked, name: AnalyticsEventName.PersonalInformationClicked)
        default:
            return
        }
    }
}

extension ProfileOptionsViewController: DownloadCellDelagete {
    func didTapWifiSwitch(isOn: Bool, wifiSwitch: UISwitch) {
        environment.analytics.trackWifi(isOn: isOn)
        if isOn {
            environment.interface?.setDownloadOnlyOnWifiPref(isOn)
        } else {
            let alertController = UIAlertController().showAlert(withTitle: Strings.cellularDownloadEnabledTitle, message: Strings.cellularDownloadEnabledMessage, cancelButtonTitle: nil, onViewController: self) { _, _, _ in }
            alertController.addButton(withTitle: Strings.doNotAllow) { [weak self] _ in
                self?.environment.analytics.trackWifi(allowed: false)
                wifiSwitch.setOn(true, animated: true)
            }
            alertController.addButton(withTitle: Strings.allow) { [weak self] _ in
                self?.environment.interface?.setDownloadOnlyOnWifiPref(isOn)
                self?.environment.analytics.trackWifi(allowed: true)
            }
        }
    }
    
    func didTapVideoQuality() {
        environment.analytics.trackEvent(with: AnalyticsDisplayName.ProfileVideoDownloadQualityClicked, name: AnalyticsEventName.ProfileVideoDownloadQualityClicked)
        environment.router?.showDownloadVideoQuality(from: self, delegate: self)
    }
}

extension ProfileOptionsViewController: VideoDownloadQualityDelegate {
    func didUpdateVideoQuality() {
        for cell in tableView.visibleCells where cell is VideoSettingCell {
            if let cell = cell as? VideoSettingCell {
                cell.updateVideoDownloadQualityLabel()
            }
        }
    }
}

extension ProfileOptionsViewController: HelpCellDelegate {
    func didTapEmail() {
        environment.analytics.trackProfileOptionClcikEvent(displayName: AnalyticsDisplayName.EmailSupportClicked, name: AnalyticsEventName.EmailSupportClicked)
        launchEmailComposer()
    }
    
    func didTapFAQ() {
        guard let faqURL = environment.config.faqURL, let url = URL(string: faqURL) else { return }
        environment.analytics.trackProfileOptionClcikEvent(displayName: AnalyticsDisplayName.FAQClicked, name: AnalyticsEventName.FAQClicked)
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

extension ProfileOptionsViewController: RestorePurchasesCellDelegate {
    func didTapRestorePurchases() {
        environment.analytics.trackRestorePurchaseClicked()
        enableUserInteraction(enable: false)
        let indicator = showProgressIndicator()
        var unfinishedSKU = ""

        let userUnfinishedPurchases = CourseUpgradeHelper.shared.savedUnfinishedIAPSKUsForCurrentUser() ?? []
        let storeUnfinishedPurchases = PaymentManager.shared.unfinishedProductIDs

        for userUnfinishedPurchase in userUnfinishedPurchases.reversed() {
            if storeUnfinishedPurchases.contains(userUnfinishedPurchase) {
                unfinishedSKU = userUnfinishedPurchase
                break
            }
        }

        if !unfinishedSKU.isEmpty {
            resolveUnfinishedPayment(for: unfinishedSKU, indicator: indicator)
        }
        else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.hideProgressIndicator(indicator: indicator, showSuccess: true)
            }
        }
    }

    private func showProgressIndicator() -> UIAlertController? {
        guard let topController = UIApplication.shared.topMostController() else { return nil }

        return UIAlertController().showProgressDialogAlert(viewController: topController, message: Strings.CourseUpgrade.Restore.inprogressText, completion: nil)
    }

    @objc func hideProgressIndicator(indicator: UIAlertController?, showSuccess: Bool = false) {
        indicator?.dismiss(animated: true) { [weak self] in
            if showSuccess {
                CourseUpgradeHelper.shared.showRestorePurchasesAlert(environment: self?.environment)
            }
        }
        enableUserInteraction(enable: true)
    }

    private func enableUserInteraction(enable: Bool) {
        isModalDismissable = enable
        DispatchQueue.main.async { [weak self] in
            self?.navigationItem.rightBarButtonItem?.isEnabled = enable
            self?.view.isUserInteractionEnabled = enable
        }
    }

    private func resolveUnfinishedPayment(for sku: String, indicator: UIAlertController?) {
        guard let course = environment.interface?.course(fromSKU: sku) else {
                  enableUserInteraction(enable: true)
                  DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                      self?.hideProgressIndicator(indicator: indicator, showSuccess: true)
                  }
                  return
              }

        let pacing: String = course.isSelfPaced == true ? "self" : "instructor"
        CourseUpgradeHelper.shared.setupHelperData(environment: environment, pacing: pacing, courseID: course.course_id ?? "", coursePrice: "", screen: .myCourses)
        environment.analytics.trackCourseUnfulfilledPurchaseInitiated(courseID: course.course_id ?? "", pacing: pacing, screen: .myCourses, flowType: CourseUpgradeHandler.CourseUpgradeMode.restore.rawValue)
        let upgradeHandler = CourseUpgradeHandler(for: course, environment: environment)
        upgradeHandler.upgradeCourse(with: .restore) { [weak self] state in

            switch state {
            case .complete:
                self?.enableUserInteraction(enable: true)
                self?.hideProgressIndicator(indicator: indicator)
                CourseUpgradeHelper.shared.handleCourseUpgrade(upgradeHadler: upgradeHandler, state: .success(course.course_id ?? "", nil))
                break
            case .error(let type, let error):
                self?.enableUserInteraction(enable: true)
                self?.hideProgressIndicator(indicator: indicator)
                CourseUpgradeHelper.shared.handleCourseUpgrade(upgradeHadler: upgradeHandler, state: .error(type, error))
                break
            default:
                break
            }
        }
    }
}

extension ProfileOptionsViewController: PrivacyCellCellDelegate {
    func didTapURL(type: PrivacyType) {
        let URL: URL?
        let title: String
        
        switch type {
        case .privacy:
            URL = environment.config.agreementURLsConfig.privacyPolicyURL
            title = Strings.ProfileOptions.Privacy.privacyPolicy
            environment.analytics.trackEvent(with: .PrivacyPolicyClicked, name: .PrivacyPolicyClicked)
        case .cookie:
            URL = environment.config.agreementURLsConfig.cookiePolicyURL
            title = Strings.ProfileOptions.Privacy.cookiePolicy
            environment.analytics.trackEvent(with: .CookiePolicyClicked, name: .CookiePolicyClicked)
        case .dataSellConsent:
            URL = environment.config.agreementURLsConfig.dataSellConsentURL
            title = Strings.ProfileOptions.Privacy.dataSellConsent
            environment.analytics.trackEvent(with: .DataSellConsentClicked, name: .DataSellConsentClicked)
        }
        
        if let URL = URL {
            environment.router?.showBrowserViewController(from: self, title: title, url: URL, modal: false)
        }
    }
}

extension ProfileOptionsViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        return isModalDismissable
    }
}

extension ProfileOptionsViewController: SignoutCellDelegate {
    func didSignout() {
        OEXFileUtility.nukeUserPIIData()
        dismiss(animated: true) { [weak self] in
            self?.environment.router?.logout()
        }
    }
}

extension ProfileOptionsViewController: DeleteAccountCellDelegate {
    func didTapDeleteAccount() {
        guard let topController = UIApplication.shared.topMostController(), let URLString = environment.config.deleteAccountURL, let URL = URL(string: URLString) else { return }

        environment.analytics.trackEvent(with: AnalyticsDisplayName.ProfileDeleteAccountClicked, name: AnalyticsEventName.ProfileDeleteAccountClicked)
        environment.router?.showBrowserViewController(from: topController, title: Strings.ProfileOptions.Deleteaccount.webviewTitle, url: URL)
    }
}

protocol DownloadCellDelagete: AnyObject {
    func didTapWifiSwitch(isOn: Bool, wifiSwitch: UISwitch)
    func didTapVideoQuality()
}

class VideoSettingCell: UITableViewCell {
    static let identifier = "VideoSettingCell"
    
    weak var delegate: DownloadCellDelagete?
    
    private lazy var wifiContainer = UIView()
    private lazy var videoQualityContainer = UIView()
    
    private lazy var optionLabel: UILabel = {
        let label = UILabel()
        label.attributedText = titleTextStyle.attributedString(withText: Strings.ProfileOptions.VideoSettings.title)
        label.accessibilityIdentifier = "VideoSettingCell:option-label"
        return label
    }()
    
    private lazy var videoSettingDescriptionLabel: UILabel = {
        let label = UILabel()
        label.attributedText = subtitleTextStyle.attributedString(withText: Strings.ProfileOptions.VideoSettings.heading)
        label.accessibilityIdentifier = "VideoSettingCell:video-setting-description-label"
        return label
    }()
    
    private lazy var videoSettingSubtitleLabel: UILabel = {
        let label = UILabel()
        label.attributedText = textStyle.attributedString(withText: Strings.ProfileOptions.VideoSettings.message)
        label.accessibilityIdentifier = "VideoSettingCell:video-setting-subtitle-label"
        return label
    }()
        
    lazy var wifiSwitch: UISwitch = {
        let toggleSwitch = UISwitch()
        toggleSwitch.oex_addAction({ [weak self] _ in
            self?.delegate?.didTapWifiSwitch(isOn: toggleSwitch.isOn, wifiSwitch: toggleSwitch)
        }, for: .valueChanged)
        toggleSwitch.accessibilityIdentifier = "VideoSettingCell:wifi-switch"
        
        OEXStyles.shared().standardSwitchStyle().apply(to: toggleSwitch)

        return toggleSwitch
    }()
    
    private lazy var videoQualityDescriptionLabel: UILabel = {
        let label = UILabel()
        label.attributedText = subtitleTextStyle.attributedString(withText: Strings.videoDownloadQualityTitle)
        label.accessibilityIdentifier = "VideoSettingCell:video-quality-description-label"
        return label
    }()
    
    private lazy var videoQualitySubtitleLabel: UILabel = {
        let label = UILabel()        
        label.accessibilityIdentifier = "VideoSettingCell:video-quality-subtitle-label"
        return label
    }()
    
    private lazy var chevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Icon.ChevronRight.imageWithFontSize(size: imageSize)
        imageView.tintColor = OEXStyles.shared().primaryBaseColor()
        imageView.isAccessibilityElement = false
        imageView.accessibilityIdentifier = "VideoSettingCell:chevron-image-view"
        return imageView
    }()
    
    private lazy var videoQualityButton: UIButton = {
        let button = UIButton()
        button.oex_addAction({ [weak self] _ in
            self?.delegate?.didTapVideoQuality()
        }, for: .touchUpInside)
        button.accessibilityIdentifier = "VideoSettingCell:video-quality-button"
        return button
    }()
        
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        accessibilityIdentifier = "ProfileOptionsViewController:video-setting-cell"
        
        setupViews()
        setupConstrains()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(optionLabel)
        contentView.addSubview(wifiContainer)
        wifiContainer.addSubview(videoSettingDescriptionLabel)
        wifiContainer.addSubview(wifiSwitch)
        wifiContainer.addSubview(videoSettingSubtitleLabel)
        contentView.addSubview(videoQualityContainer)
        videoQualityContainer.addSubview(videoQualityDescriptionLabel)
        videoQualityContainer.addSubview(videoQualitySubtitleLabel)
        videoQualityContainer.addSubview(chevronImageView)
        videoQualityContainer.addSubview(videoQualityButton)
    }
    
    private func setupConstrains() {
        optionLabel.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(StandardVerticalMargin + (StandardVerticalMargin / 2))
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
        }
        
        wifiContainer.snp.makeConstraints { make in
            make.top.equalTo(optionLabel.snp.bottom).offset(StandardVerticalMargin)
            make.leading.equalTo(contentView).offset(StandardVerticalMargin)
            make.trailing.equalTo(contentView).inset(StandardVerticalMargin)
            make.bottom.equalTo(videoSettingDescriptionLabel.snp.bottom).offset(StandardVerticalMargin)
        }
        
        wifiSwitch.snp.makeConstraints { make in
            make.trailing.equalTo(wifiContainer).inset(StandardVerticalMargin)
            make.centerY.equalTo(videoSettingDescriptionLabel)
        }
        
        videoSettingDescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(wifiContainer)
            make.leading.equalTo(wifiContainer).offset(StandardVerticalMargin)
            make.trailing.equalTo(wifiSwitch.snp.leading)
        }
        
        videoSettingSubtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(videoSettingDescriptionLabel.snp.bottom).offset(StandardVerticalMargin)
            make.leading.equalTo(wifiContainer).offset(StandardVerticalMargin)
            make.trailing.equalTo(wifiContainer)
            make.height.equalTo(StandardVerticalMargin * 2)
            make.bottom.equalTo(wifiContainer)
        }
        
        videoQualityContainer.snp.makeConstraints { make in
            make.top.equalTo(wifiContainer.snp.bottom).offset(StandardVerticalMargin * 2)
            make.leading.equalTo(contentView).offset(StandardVerticalMargin)
            make.trailing.equalTo(contentView).inset(StandardVerticalMargin)
            make.bottom.equalTo(contentView).inset(StandardVerticalMargin + (StandardVerticalMargin / 2))
        }
        
        videoQualityDescriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(videoQualityContainer)
            make.leading.equalTo(videoQualityContainer).offset(StandardVerticalMargin)
            make.trailing.equalTo(videoQualityContainer)
        }
        
        chevronImageView.snp.makeConstraints { make in
            make.height.equalTo(imageSize)
            make.width.equalTo(imageSize)
            make.trailing.equalTo(videoQualityContainer).inset(StandardHorizontalMargin / 2)
            make.centerY.equalTo(videoQualityContainer)
        }
        
        videoQualitySubtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(videoQualityDescriptionLabel.snp.bottom).offset(StandardVerticalMargin)
            make.leading.equalTo(videoQualityContainer).offset(StandardVerticalMargin)
            make.trailing.equalTo(videoQualityContainer)
            make.height.equalTo(StandardVerticalMargin * 2)
            make.bottom.equalTo(videoQualityContainer)
        }
        
        videoQualityButton.snp.makeConstraints { make in
            make.edges.equalTo(videoQualityContainer)
        }
    }
    
    func updateVideoDownloadQualityLabel() {
        videoQualitySubtitleLabel.attributedText = textStyle.attributedString(withText: OEXInterface.shared().getVideoDownladQuality().title)
    }
}

class PersonalInformationCell: UITableViewCell {
    static let identifier = "PersonalInformationCell"
    
    private var username: String? {
        didSet {
            guard let username = username else { return }
            usernameLabel.attributedText = subtitleTextStyle.attributedString(withText: Strings.ProfileOptions.UserProfile.username(username: username))
        }
    }
    
    private var email: String? {
        didSet {
            guard let email = email else { return }
            emailLabel.attributedText = subtitleTextStyle.attributedString(withText: Strings.ProfileOptions.UserProfile.email(email: email))
        }
    }

    var profileSubtitle: String? {
        didSet {
            subtitleLabel.attributedText = textStyle.attributedString(withText: profileSubtitle)
        }
    }

    private lazy var profileView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: imageSize + 10, height: imageSize + 10))
        view.accessibilityIdentifier = "PersonalInformationCell:profile-view"
        return view
    }()
    
    private lazy var chevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Icon.ChevronRight.imageWithFontSize(size: imageSize)
        imageView.tintColor = OEXStyles.shared().primaryBaseColor()
        imageView.isAccessibilityElement = false
        imageView.accessibilityIdentifier = "PersonalInformationCell:chevron-image-view"
        return imageView
    }()
    
    lazy var profileImageView: ProfileImageView = {
        let view = ProfileImageView(defaultStyle: false)
        view.accessibilityIdentifier = "PersonalInformationCell:profile-image-view"
        return view
    }()
    
    private lazy var optionLabel: UILabel = {
        let label = UILabel()
        label.attributedText = titleTextStyle.attributedString(withText: Strings.ProfileOptions.UserProfile.title)
        label.accessibilityIdentifier = "PersonalInformationCell:option-label"
        return label
    }()
    
    private lazy var emailLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "PersonalInformationCell:email-label"
        return label
    }()
    
    private lazy var usernameLabel: UILabel = {
        let label = UILabel()
        label.accessibilityIdentifier = "PersonalInformationCell:username-label"
        return label
    }()

    private lazy var subtitleLabel: UILabel = {
            let label = UILabel()
            label.accessibilityIdentifier = "PersonalInformationCell:subtitle-label"
            return label
        }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        accessibilityIdentifier = "ProfileOptionsViewController:wifi-cell"
        
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let borderStyle = OEXStyles.shared().profileImageViewBorder(width: 1)
        profileView.applyBorderStyle(style: borderStyle)
        profileView.layer.cornerRadius = imageSize / 2
        profileView.clipsToBounds = true
    }
    
    private func setupViews() {
        contentView.addSubview(optionLabel)
        contentView.addSubview(emailLabel)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(chevronImageView)
        contentView.addSubview(profileView)
        profileView.addSubview(profileImageView)
    }
    
    private func setupConstrains() {
        optionLabel.snp.remakeConstraints { make in
            make.top.equalTo(contentView).offset(StandardVerticalMargin + (StandardVerticalMargin / 2))
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
        }
        
        emailLabel.snp.remakeConstraints { make in
            make.top.equalTo(optionLabel.snp.bottom).offset(StandardVerticalMargin)
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(profileView.snp.leading)
        }
        
        usernameLabel.snp.remakeConstraints { make in
            make.top.equalTo(emailLabel.snp.bottom).offset(StandardVerticalMargin / 2)
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(emailLabel)

            if profileSubtitle == nil {
                make.bottom.equalTo(contentView).inset(StandardVerticalMargin + (StandardVerticalMargin / 2))
            }
        }

        if profileSubtitle != nil {
            subtitleLabel.snp.remakeConstraints { make in
                make.top.equalTo(usernameLabel.snp.bottom).offset(StandardVerticalMargin)
                make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
                make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
                make.bottom.equalTo(contentView).inset(StandardVerticalMargin + (StandardVerticalMargin / 2))
            }
        }
        
        chevronImageView.snp.remakeConstraints { make in
            make.height.equalTo(imageSize)
            make.width.equalTo(imageSize)
            make.centerY.equalTo(contentView)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
        }
        
        profileView.snp.remakeConstraints { make in
            make.height.equalTo(imageSize)
            make.width.equalTo(imageSize)
            make.centerY.equalTo(contentView)
            make.trailing.equalTo(chevronImageView.snp.leading).inset(-StandardHorizontalMargin / 2)
        }
        
        profileImageView.snp.remakeConstraints { make in
            make.edges.equalTo(profileView)
        }
    }
    
    func update(username: String, email: String) {
        self.username = username
        self.email = email
        
        setupConstrains()
    }
}

protocol RestorePurchasesCellDelegate: AnyObject {
    func didTapRestorePurchases()
}

class RestorePurchasesCell: UITableViewCell {
    static let identifier = "RestorePurchasesCell"

    weak var delegate: RestorePurchasesCellDelegate?

    private lazy var optionLabel: UILabel = {
        let label = UILabel()
        label.attributedText = titleTextStyle.attributedString(withText: Strings.ProfileOptions.Purchases.title)
        label.accessibilityIdentifier = "RestorePurchasesCell:option-label"
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.attributedText = subtitleTextStyle.attributedString(withText: Strings.ProfileOptions.Purchases.heading)
        label.accessibilityIdentifier = "RestorePurchasesCell:description-label"
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = textStyle.attributedString(withText: Strings.ProfileOptions.Purchases.message)
        label.accessibilityIdentifier = "RestorePurchasesCell:subtitle-label"
        return label
    }()

    private lazy var buttonStyle = OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().primaryBaseColor())

    private lazy var restoreButton: UIButton = {
        let button = UIButton()
        button.layer.borderWidth = 1
        button.layer.borderColor = OEXStyles.shared().neutralXLight().cgColor
        button.oex_addAction({ [weak self] _ in
            self?.delegate?.didTapRestorePurchases()
        }, for: .touchUpInside)

        button.setAttributedTitle(buttonStyle.attributedString(withText: Strings.ProfileOptions.Purchases.heading), for: .normal)
        button.accessibilityIdentifier = "RestorePurchasesCell:restore-button"
        return button
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        accessibilityIdentifier = "ProfileOptionsViewController:restore-purchases-cell"
        
        setupViews()
        setupConstrains()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(optionLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(restoreButton)
    }
    
    private func setupConstrains() {
        optionLabel.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(StandardVerticalMargin + (StandardVerticalMargin / 2))
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(optionLabel.snp.bottom).offset(StandardVerticalMargin)
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(StandardVerticalMargin / 2)
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
            make.height.greaterThanOrEqualTo(StandardVerticalMargin * 2)
        }

        restoreButton.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(StandardVerticalMargin)
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
            make.height.equalTo(StandardVerticalMargin * 5)
            make.bottom.equalTo(contentView).inset(StandardVerticalMargin + (StandardVerticalMargin / 2))
        }
    }
}


enum PrivacyType: String {
    case privacy, cookie, dataSellConsent
}

protocol PrivacyCellCellDelegate: AnyObject {
    func didTapURL(type: PrivacyType)
}

class PrivacyCell: UITableViewCell {
    
    class PrivacyCellView: UIView {
        var type: PrivacyType = .privacy
        var owner: PrivacyCell? = nil
        
        init(type: PrivacyType, owner: PrivacyCell?) {
            super.init(frame: .zero)
            
            self.type = type
            self.owner = owner
            setupView()
        }
        
        var title: String {
            switch type {
            case .privacy:
                return Strings.ProfileOptions.Privacy.privacyPolicy
            case .cookie:
                return Strings.ProfileOptions.Privacy.cookiePolicy
            case .dataSellConsent:
                return Strings.ProfileOptions.Privacy.dataSellConsent
            }
        }
        
        private lazy var button: UIButton = {
            let buttonStyle = OEXTextStyle(weight: .bold, size: .base, color: OEXStyles.shared().primaryBaseColor())
            
            let button = UIButton()
            button.accessibilityIdentifier = "PrivacyCellView:\(type)-button"
            button.contentHorizontalAlignment = .left
            button.setAttributedTitle(buttonStyle.attributedString(withText: title), for: UIControl.State())
            button.oex_addAction({ [weak self] _ in
                guard let self = self else { return }
                self.owner?.delegate?.didTapURL(type: self.type)
            }, for: .touchUpInside)
            
            return button
        }()
        
        private lazy var chevronImageView: UIImageView = {
            let imageView = UIImageView()
            imageView.image = Icon.ChevronRight.imageWithFontSize(size: imageSize)
            imageView.tintColor = OEXStyles.shared().primaryBaseColor()
            imageView.isAccessibilityElement = false
            imageView.accessibilityIdentifier = "PrivacyCellView:chevron-image-view"
            return imageView
        }()
        
        private func setupView() {
            addSubview(button)
            addSubview(chevronImageView)
            
            button.snp.makeConstraints { make in
                make.top.equalTo(self)
                make.leading.equalTo(self)
                make.trailing.equalTo(chevronImageView.snp.leading)
                make.bottom.equalTo(self)
                make.height.equalTo(30)
            }
            
            chevronImageView.snp.makeConstraints { make in
                make.height.equalTo(imageSize)
                make.width.equalTo(imageSize)
                make.trailing.equalTo(self).inset(2 * StandardHorizontalMargin)
                make.centerY.equalTo(button)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    static let identifier = "PrivacyCell"
    weak var delegate: PrivacyCellCellDelegate?
    
    private var privacyPolicyEnabled = false
    private var cookiePolicyEnabled = false
    private var dataSellConsentEnabled = false
    
    private lazy var optionLabel: UILabel = {
        let label = UILabel()
        label.attributedText = titleTextStyle.attributedString(withText: Strings.ProfileOptions.Privacy.title)
        label.accessibilityIdentifier = "PrivacyCell:option-label"
        return label
    }()
    
    private lazy var privacyView: PrivacyCellView = {
        let view = PrivacyCellView(type: .privacy, owner: self)
        view.accessibilityIdentifier = "PrivacyCell:privacy-policy-view"
        return view
    }()
    
    private lazy var cookieView: PrivacyCellView = {
        let view = PrivacyCellView(type: .cookie, owner: self)
        view.accessibilityIdentifier = "PrivacyCell:cookie-policy-view"
        return view
    }()
    
    private lazy var dataSellConsentView: PrivacyCellView = {
        let view = PrivacyCellView(type: .dataSellConsent, owner: self)
        view.accessibilityIdentifier = "PrivacyCell:data-sell-consent--view"
        return view
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        accessibilityIdentifier = "ProfileOptionsViewController:restore-purchases-cell"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(privacyEnabled: Bool, cookieEnabled: Bool, dataSellConsentEnabled: Bool) {
        privacyPolicyEnabled = privacyEnabled
        cookiePolicyEnabled = cookieEnabled
        self.dataSellConsentEnabled = dataSellConsentEnabled
        setupViews()
        setupConstrains()
    }
    
    private func setupViews() {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        contentView.addSubview(optionLabel)
        if privacyPolicyEnabled {
            contentView.addSubview(privacyView)
        }
        if cookiePolicyEnabled {
            contentView.addSubview(cookieView)
        }
        if dataSellConsentEnabled {
            contentView.addSubview(dataSellConsentView)
        }
    }
    
    private func setupConstrains() {
        var upperView: UIView = optionLabel
        optionLabel.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(StandardVerticalMargin + (StandardVerticalMargin / 2))
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
        }
        
        if privacyPolicyEnabled {
            privacyView.snp.makeConstraints { make in
                make.top.equalTo(upperView.snp.bottom).offset(StandardVerticalMargin)
                make.trailing.equalTo(contentView).offset(StandardHorizontalMargin)
                make.leading.equalTo(contentView).inset(StandardHorizontalMargin)
                
                if !cookiePolicyEnabled && !dataSellConsentEnabled {
                    make.bottom.equalTo(contentView).inset(StandardVerticalMargin + (StandardVerticalMargin / 2))
                }
            }
            upperView = privacyView
        }
        
        if cookiePolicyEnabled {
            cookieView.snp.makeConstraints { make in
                make.top.equalTo(upperView.snp.bottom).offset(StandardVerticalMargin / 2)
                make.trailing.equalTo(upperView)
                make.leading.equalTo(upperView)
                
                if !dataSellConsentEnabled {
                    make.bottom.equalTo(contentView).inset((StandardVerticalMargin + (StandardVerticalMargin / 2)))
                }
            }
            upperView = cookieView
        }
        
        if dataSellConsentEnabled {
            dataSellConsentView.snp.makeConstraints { make in
                make.top.equalTo(upperView.snp.bottom).offset(StandardVerticalMargin / 2)
                make.trailing.equalTo(upperView)
                make.leading.equalTo(upperView)
                make.bottom.equalTo(contentView).inset(StandardVerticalMargin + (StandardVerticalMargin / 2))
            }
        }
    }
}

protocol HelpCellDelegate: AnyObject {
    func didTapEmail()
    func didTapFAQ()
}

class HelpCell: UITableViewCell {
    static let identifier = "HelpCell"
    
    weak var delegate: HelpCellDelegate?
    
    private var feedbackEnabled: Bool = false
    private var faqEnabled: Bool = false
    
    private let lineSpacing: CGFloat = 4
    
    private var platformName: String? {
        didSet {
            feedbackSubtitleLabel.attributedText = textStyle.attributedString(withText: Strings.ProfileOptions.Help.Message.feedback)
        }
    }
    
    private lazy var feedbackSupportContainer: UIView = {
        let view = UIView()
        view.accessibilityIdentifier = "HelpCell:feedback-support-container"
        return view
    }()
    
    private lazy var faqContainer: UIView = {
        let view = UIView()
        view.accessibilityIdentifier = "HelpCell:faq-container"
        return view
    }()
    
    private lazy var optionLabel: UILabel = {
        let label = UILabel()
        label.attributedText = titleTextStyle.attributedString(withText: Strings.ProfileOptions.Help.title)
        label.accessibilityIdentifier = "HelpCell:option-label"
        return label
    }()
    
    private lazy var buttonStyle = OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().primaryBaseColor())
    
    private lazy var feedbackLabel: UILabel = {
        let label = UILabel()
        label.attributedText = subtitleTextStyle.attributedString(withText: Strings.ProfileOptions.Help.Heading.feedback)
        label.accessibilityIdentifier = "HelpCell:feedback-label"
        return label
    }()
    
    private lazy var feedbackSubtitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.accessibilityIdentifier = "HelpCell:feedback-subtitle-label"
        return label
    }()
    
    private lazy var emailFeedbackButton: UIButton = {
        let button = UIButton()
        button.layer.borderWidth = 1
        button.layer.borderColor = OEXStyles.shared().neutralXLight().cgColor
        button.oex_addAction({ [weak self] _ in
            self?.delegate?.didTapEmail()
        }, for: .touchUpInside)
        
        button.setAttributedTitle(buttonStyle.attributedString(withText: Strings.ProfileOptions.Help.ButtonTitle.feedback), for: .normal)
        button.accessibilityIdentifier = "HelpCell:email-feedback-button"
        return button
    }()
    
    private lazy var supportLabel: UILabel = {
        let label = UILabel()
        label.attributedText = subtitleTextStyle.attributedString(withText: Strings.ProfileOptions.Help.Heading.support)
        label.accessibilityIdentifier = "HelpCell:support-label"
        return label
    }()
    
    private lazy var supportSubtitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = textStyle.attributedString(withText:
                                                            Strings.ProfileOptions.Help.Message.support(platformName: platformName ?? "")).setLineSpacing(lineSpacing)
        label.accessibilityIdentifier = "HelpCell:support-subtitle-label"
        return label
    }()
    
    private lazy var faqButton: UIButton = {
        let button = UIButton()
        button.layer.borderWidth = 1
        button.layer.borderColor = OEXStyles.shared().neutralXLight().cgColor
        button.oex_addAction({ [weak self] _ in
            self?.delegate?.didTapFAQ()
        }, for: .touchUpInside)
        
        let faqButtonTitle = [buttonStyle.attributedString(withText: Strings.ProfileOptions.Help.ButtonTitle.viewFaq), faqButtonIcon]
        let attributedText = NSAttributedString.joinInNaturalLayout(attributedStrings: faqButtonTitle)
        button.setAttributedTitle(attributedText, for: .normal)
        button.accessibilityIdentifier = "HelpCell:view-faq-button"
        return button
    }()
    
    private lazy var faqButtonIcon: NSAttributedString = {
        let icon = Icon.OpenInBrowser.imageWithFontSize(size: 18).image(with: OEXStyles.shared().primaryBaseColor())
        let attachment = NSTextAttachment()
        attachment.image = icon
        
        if let image = attachment.image {
            attachment.bounds = CGRect(x: 0, y: -4.0, width: image.size.width, height: image.size.height)
        }
        
        return NSAttributedString(attachment: attachment)
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        accessibilityIdentifier = "ProfileOptionsViewController:help-cell"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(feedbackEnabled: Bool, faqEnabled: Bool, platformName: String) {
        self.feedbackEnabled = feedbackEnabled
        self.faqEnabled = faqEnabled
        self.platformName = platformName
        setupViews()
        setupConstrains()
    }
    
    private func setupViews() {
        contentView.addSubview(optionLabel)
        
        if feedbackEnabled {
            feedbackSupportContainer.addSubview(feedbackLabel)
            feedbackSupportContainer.addSubview(feedbackSubtitleLabel)
            feedbackSupportContainer.addSubview(emailFeedbackButton)
            contentView.addSubview(feedbackSupportContainer)
        }
        
        if faqEnabled {
            faqContainer.addSubview(supportLabel)
            faqContainer.addSubview(supportSubtitleLabel)
            faqContainer.addSubview(faqButton)
            contentView.addSubview(faqContainer)
        }
    }
    
    private func setupConstrains() {
        optionLabel.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(StandardVerticalMargin + (StandardVerticalMargin / 2))
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
        }
        
        if feedbackEnabled {
            feedbackSupportContainer.snp.makeConstraints { make in
                make.top.equalTo(optionLabel.snp.bottom).offset(StandardVerticalMargin)
                make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
                make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
                
                if faqEnabled {
                    make.bottom.equalTo(emailFeedbackButton.snp.bottom).offset(StandardVerticalMargin)
                } else {
                    make.bottom.equalTo(contentView).inset(StandardVerticalMargin)
                }
            }
            
            feedbackLabel.snp.makeConstraints { make in
                make.top.equalTo(feedbackSupportContainer)
                make.leading.equalTo(feedbackSupportContainer)
                make.trailing.equalTo(feedbackSupportContainer)
            }
            
            feedbackSubtitleLabel.snp.makeConstraints { make in
                make.top.equalTo(feedbackLabel.snp.bottom).offset(StandardVerticalMargin)
                make.leading.equalTo(feedbackSupportContainer)
                make.trailing.equalTo(feedbackSupportContainer)
                make.height.greaterThanOrEqualTo(StandardVerticalMargin * 2)
            }
            
            emailFeedbackButton.snp.makeConstraints { make in
                make.top.equalTo(feedbackSubtitleLabel.snp.bottom).offset(StandardVerticalMargin)
                make.leading.equalTo(feedbackSupportContainer)
                make.trailing.equalTo(feedbackSupportContainer)
                make.height.equalTo(StandardVerticalMargin * 5)
                
                if !faqEnabled {
                    make.bottom.equalTo(feedbackSupportContainer).inset(StandardVerticalMargin)
                }
            }
        }
        
        if faqEnabled {
            faqContainer.snp.makeConstraints { make in
                if feedbackEnabled {
                    make.top.equalTo(feedbackSupportContainer.snp.bottom).offset(StandardVerticalMargin + (StandardVerticalMargin / 2))
                } else {
                    make.top.equalTo(optionLabel.snp.bottom).offset(StandardVerticalMargin + (StandardVerticalMargin / 2))
                }
                make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
                make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
                make.bottom.equalTo(contentView).inset(StandardVerticalMargin)
            }
            
            supportLabel.snp.makeConstraints { make in
                make.top.equalTo(faqContainer).offset(StandardVerticalMargin)
                make.leading.equalTo(faqContainer)
                make.trailing.equalTo(faqContainer)
            }
            
            supportSubtitleLabel.snp.makeConstraints { make in
                make.top.equalTo(supportLabel.snp.bottom).offset(StandardVerticalMargin)
                make.leading.equalTo(faqContainer)
                make.trailing.equalTo(faqContainer)
                make.height.greaterThanOrEqualTo(StandardVerticalMargin * 2)
            }
            
            faqButton.snp.makeConstraints { make in
                make.top.equalTo(supportSubtitleLabel.snp.bottom).offset(StandardVerticalMargin)
                make.leading.equalTo(faqContainer)
                make.trailing.equalTo(faqContainer)
                make.height.equalTo(StandardVerticalMargin * 5)
                make.bottom.equalTo(faqContainer).inset(StandardVerticalMargin + (StandardVerticalMargin / 2))
            }
        }
    }
}

protocol SignoutCellDelegate: AnyObject {
    func didSignout()
}

class SignOutVersionCell: UITableViewCell {
    static let identifier = "SignOutVersionCell"
    
    weak var delegate: SignoutCellDelegate?
    
    private lazy var signoutButton: UIButton = {
        let button = UIButton()
        button.layer.borderWidth = 1
        button.layer.borderColor = OEXStyles.shared().neutralXLight().cgColor
        button.oex_addAction({ [weak self] _ in
            self?.delegate?.didSignout()
        }, for: .touchUpInside)
        
        let style = OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().primaryBaseColor())
        button.setAttributedTitle(style.attributedString(withText: Strings.ProfileOptions.Signout.buttonTitle), for: .normal)
        button.accessibilityIdentifier = "SignOutVersionCell:signout-button"
        return button
    }()
    
    private lazy var versionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = textStyle.attributedString(withText: Strings.versionDisplay(number: Bundle.main.oex_shortVersionString(), environment: ""))
        label.accessibilityIdentifier = "SignOutVersionCell:version-label"
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        accessibilityIdentifier = "ProfileOptionsViewController:signout-version-cell"
        
        setupViews()
        setupConstrains()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(signoutButton)
        contentView.addSubview(versionLabel)
    }
    
    private func setupConstrains() {
        signoutButton.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(StandardVerticalMargin * 2)
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
            make.height.equalTo(StandardVerticalMargin * 5)
        }
        
        versionLabel.snp.makeConstraints { make in
            make.top.equalTo(signoutButton.snp.bottom).offset(StandardVerticalMargin * 2)
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
            make.bottom.equalTo(contentView).inset(StandardVerticalMargin * 2)
        }
    }
}

protocol DeleteAccountCellDelegate: AnyObject {
    func didTapDeleteAccount()
}

class DeleteAccountCell: UITableViewCell {
    static let identifier = "DeleteAccountCell"

    weak var delegate: DeleteAccountCellDelegate?
    private let infoTextStyle = OEXMutableTextStyle(weight: .light, size: .xSmall, color: OEXStyles.shared().neutralXDark())

    private lazy var deleteAccountButton: UIButton = {
        let button = UIButton()
        button.layer.borderWidth = 1
        button.layer.borderColor = OEXStyles.shared().errorBase().cgColor
        button.oex_addAction({ [weak self] _ in
            self?.delegate?.didTapDeleteAccount()
        }, for: .touchUpInside)

        let style = OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().errorBase())
        button.setAttributedTitle(style.attributedString(withText: Strings.ProfileOptions.Deleteaccount.buttonTitle), for: .normal)
        button.accessibilityIdentifier = "DeleteAccountCell:signout-button"
        return button
    }()

    private lazy var infoLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = infoTextStyle.attributedString(withText: Strings.ProfileOptions.Deleteaccount.infoMessage).setLineSpacing(4)
        label.accessibilityIdentifier = "DeleteAccountCell:info-label"
        label.textAlignment = .center
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        selectionStyle = .none
        accessibilityIdentifier = "ProfileOptionsViewController:delete-account-cell"
        contentView.backgroundColor = OEXStyles.shared().neutralWhite()
        setupViews()
        setupConstrains()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        contentView.addSubview(deleteAccountButton)
        contentView.addSubview(infoLabel)
    }

    private func setupConstrains() {
        deleteAccountButton.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(StandardVerticalMargin * 3)
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
            make.height.equalTo(StandardVerticalMargin * 5)
        }

        infoLabel.snp.makeConstraints { make in
            make.top.equalTo(deleteAccountButton.snp.bottom).offset(10)
            make.leading.equalTo(deleteAccountButton)
            make.trailing.equalTo(deleteAccountButton)
            make.bottom.equalTo(contentView).inset(StandardVerticalMargin * 2)
        }
    }
}
