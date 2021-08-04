//
//  ProfileOptionsViewController.swift
//  edX
//
//  Created by Muhammad Umer on 27/07/2021.
//  Copyright © 2021 edX. All rights reserved.
//

import UIKit
import MessageUI

fileprivate let titleTextStyle = OEXMutableTextStyle(weight: .light, size: .small, color: OEXStyles.shared().neutralXDark())
fileprivate let subtitleTextStyle = OEXMutableTextStyle(weight: .bold, size: .base, color: OEXStyles.shared().primaryDarkColor())

class ProfileOptionsViewController: UIViewController {
    
    private enum ProfileOptions {
        case wifiSetting
        case personalInformation
        case restorePurchase
        case help(Bool, Bool)
        case signout
    }
    
    typealias Environment = OEXStylesProvider & OEXConfigProvider & NetworkManagerProvider & DataManagerProvider & OEXRouterProvider & OEXSessionProvider & OEXInterfaceProvider & OEXAnalyticsProvider
    
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
        tableView.register(WifiSettingCell.self, forCellReuseIdentifier: WifiSettingCell.identifier)
        tableView.register(PersonalInformationCell.self, forCellReuseIdentifier: PersonalInformationCell.identifier)
        tableView.register(RestorePurchasesCell.self, forCellReuseIdentifier: RestorePurchasesCell.identifier)
        tableView.register(HelpCell.self, forCellReuseIdentifier: HelpCell.identifier)
        tableView.register(SignOutVersionCell.self, forCellReuseIdentifier: SignOutVersionCell.identifier)

        return tableView
    }()
    
    private var options: [ProfileOptions] = []
    
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
        
        environment.analytics.trackScreen(withName: AnalyticsScreenName.Profile.rawValue)
        
        setupViews()
        addCloseButton()
        configureOptions()
        setupProfileLoader()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.view.backgroundColor = environment.styles.navigationBarColor()
        setupProfileLoader()
    }
    
    private func setupViews() {
        view.backgroundColor = environment.styles.standardBackgroundColor()
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view)
        }
    }
    
    private func setupProfileLoader() {
        guard environment.config.profilesEnabled
        else { return }
        let profileFeed = environment.dataManager.userProfileManager.feedForCurrentUser()
        
        profileFeed.output.listen(self,  success: { [weak self] profile in
            guard let weakSelf = self else { return }
            for cell in weakSelf.tableView.visibleCells where cell is PersonalInformationCell {
                if let personalInformationCell = cell as? PersonalInformationCell {
                    personalInformationCell.profileSubtitle = profile.sharingLimitedProfile ? Strings.Settings.UserProfile.message : ""
                    personalInformationCell.profileImageView.remoteImage = profile.image(networkManager: weakSelf.environment.networkManager)
                }
            }
        }, failure : { _ in
            Logger.logError("Profiles", "Unable to fetch profile")
        })
        profileFeed.refresh()
    }
    
    private func addCloseButton() {
        let closeButton = UIBarButtonItem(image: Icon.Close.imageWithFontSize(size: crossButtonSize), style: .plain, target: nil, action: nil)
        closeButton.accessibilityLabel = Strings.Accessibility.closeLabel
        closeButton.accessibilityHint = Strings.Accessibility.closeHint
        closeButton.accessibilityIdentifier = "ProfileViewController:close-button"
        navigationItem.rightBarButtonItem = closeButton
        
        closeButton.oex_setAction { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
    }
    
    private func configureOptions() {
        options.append(.wifiSetting)
        
        if environment.config.profilesEnabled {
            options.append(.personalInformation)
        }
        
        if environment.config.inappPurchasesEnabled {
            options.append(.restorePurchase)
        }
        
        let isFeedbackEnabled =  environment.config.feedbackEmailAddress() != nil
        let isFaqEnabled = environment.config.faqURL != nil
        
        if isFeedbackEnabled || isFaqEnabled {
            options.append(.help(isFeedbackEnabled, isFaqEnabled))
        }
        
        options.append(.signout)
        
        tableView.reloadData()
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
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
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch options[indexPath.row] {
        case .wifiSetting:
            return wifiCell(tableView, indexPath: indexPath)
            
        case .personalInformation:
            return personalInformationCell(tableView, indexPath: indexPath)
        
        case .restorePurchase:
            return restorePurchaseCell(tableView, indexPath: indexPath)
            
        case .help(let isFeedbackEnabled, let isFaqEnabled):
            return helpCell(tableView, indexPath: indexPath, isFeedbackEnabled: isFeedbackEnabled, isFaqEnabled: isFaqEnabled)
            
        case .signout:
            return signoutCell(tableView, indexPath: indexPath)
        }
    }
    
    private func wifiCell(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: WifiSettingCell.identifier, for: indexPath) as! WifiSettingCell
        cell.delegate = self
        cell.wifiSwitch.isOn = environment.interface?.shouldDownloadOnlyOnWifi ?? false
        return cell
    }
    
    private func personalInformationCell(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: PersonalInformationCell.identifier, for: indexPath) as! PersonalInformationCell
        
        guard environment.config.profilesEnabled,
              let username = environment.session.currentUser?.username,
              let email = environment.session.currentUser?.email else { return cell }
        cell.update(username: username, email: email)
        
        return cell
    }
    
    private func restorePurchaseCell(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: RestorePurchasesCell.identifier, for: indexPath) as! RestorePurchasesCell
    }

    private func helpCell(_ tableView: UITableView, indexPath: IndexPath, isFeedbackEnabled: Bool, isFaqEnabled: Bool) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HelpCell.identifier, for: indexPath) as! HelpCell
        cell.delegate = self
        cell.update(isFeedbackEnabled: isFeedbackEnabled, isFaqEnabled: isFaqEnabled)
        
        return cell
    }

    private func signoutCell(_ tableView: UITableView, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SignOutVersionCell.identifier, for: indexPath) as! SignOutVersionCell
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

extension ProfileOptionsViewController: WifiSettingCellDelagete {
    func didSelectedwifiSwitch(isOn: Bool, wifiSwitch: UISwitch) {
        environment.analytics.trackWifi(isOn: isOn)
        if isOn {
            UIAlertController().showIn(viewController: self, title: Strings.cellularDownloadEnabledTitle, message: Strings.cellularDownloadEnabledMessage, preferredStyle: .alert, cancelButtonTitle: Strings.allow, destructiveButtonTitle: nil, otherButtonsTitle: [Strings.doNotAllow]) { [weak self] alertController, _, index in
                if index == alertController.cancelButtonIndex {
                    self?.environment.interface?.setDownloadOnlyOnWifiPref(isOn)
                } else {
                    wifiSwitch.isOn = false
                }
            }
        } else {
            environment.interface?.setDownloadOnlyOnWifiPref(isOn)
        }
    }
}

extension ProfileOptionsViewController: HelpCellDelegate {
    func didSelectEmail() {
        environment.analytics.trackProfileOptionClcikEvent(displayName: AnalyticsDisplayName.EmailSupportClicked, name: AnalyticsEventName.EmailSupportClicked)
        launchEmailComposer()
    }
    
    func didSelectFAQ() {
        guard let faqURL = environment.config.faqURL, let url = URL(string: faqURL) else { return }
        environment.analytics.trackProfileOptionClcikEvent(displayName: AnalyticsDisplayName.FAQClicked, name: AnalyticsEventName.FAQClicked)
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

extension ProfileOptionsViewController: SignoutCellDelegate {
    func didSingout() {
        OEXFileUtility.nukeUserPIIData()
        dismiss(animated: true) { [weak self] in
            self?.environment.router?.logout()
        }
    }
}

protocol WifiSettingCellDelagete {
    func didSelectedwifiSwitch(isOn: Bool, wifiSwitch: UISwitch)
}

class WifiSettingCell: UITableViewCell {
    static let identifier = "WifiSettingCell"
    
    var delegate: WifiSettingCellDelagete?
    
    private lazy var settingLabel: UILabel = {
        let label = UILabel()
        label.attributedText = titleTextStyle.attributedString(withText: Strings.Settings.Wifi.title)
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.attributedText = subtitleTextStyle.attributedString(withText: Strings.Settings.Wifi.heading)
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.attributedText = titleTextStyle.attributedString(withText: Strings.Settings.Wifi.message)
        return label
    }()
        
    lazy var wifiSwitch: UISwitch = {
        let toggleSwitch = UISwitch()
        toggleSwitch.oex_addAction({ [weak self] _ in
            self?.delegate?.didSelectedwifiSwitch(isOn: toggleSwitch.isOn, wifiSwitch: toggleSwitch)
        }, for: .valueChanged)
        
        OEXStyles.shared().standardSwitchStyle().apply(to: toggleSwitch)

        return toggleSwitch
    }()
        
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        accessibilityIdentifier = "ProfileViewController:wifi-cell"
        
        setupViews()
        setupConstrains()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(settingLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(wifiSwitch)
        contentView.addSubview(subtitleLabel)
    }
    
    private func setupConstrains() {
        settingLabel.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(StandardVerticalMargin + (StandardVerticalMargin / 2))
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
            make.height.equalTo(StandardVerticalMargin * 2)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(settingLabel.snp.bottom).offset(StandardVerticalMargin)
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(wifiSwitch).inset(StandardHorizontalMargin)
            make.height.equalTo(wifiSwitch)
        }
        
        wifiSwitch.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(StandardVerticalMargin)
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
            make.height.equalTo(StandardVerticalMargin * 2)
            make.bottom.equalTo(contentView).inset(StandardVerticalMargin + (StandardVerticalMargin / 2))
        }
    }
}

class PersonalInformationCell: UITableViewCell {
    static let identifier = "PersonalInformationCell"
    
    var profileSubtitle: String? {
        didSet {
            subtitleLabel.attributedText = titleTextStyle.attributedString(withText: profileSubtitle)
        }
    }
    
    private lazy var userProfileImageSize = CGSize(width: 36, height: 36)
    private lazy var profileView = UIView(frame: CGRect(x: 0, y: 0, width: userProfileImageSize.width + 10, height: userProfileImageSize.height + 10))
    
    private lazy var chevronImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Icon.ChevronRight.imageWithFontSize(size: userProfileImageSize.height)
        imageView.tintColor = OEXStyles.shared().primaryBaseColor()
        imageView.isAccessibilityElement = false
        return imageView
    }()
    
    lazy var profileImageView = ProfileImageView(defaultStyle: false)
    
    private lazy var settingLabel: UILabel = {
        let label = UILabel()
        label.attributedText = titleTextStyle.attributedString(withText: Strings.Settings.UserProfile.title)
        return label
    }()
    
    private lazy var emailLabel = UILabel()
    private lazy var usernameLabel = UILabel()
    
    private lazy var subtitleLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        accessibilityIdentifier = "ProfileViewController:wifi-cell"
        
        setupViews()
        setupConstrains()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let borderStyle = OEXStyles.shared().profileImageViewBorder(width: 1)
        profileView.applyBorderStyle(style: borderStyle)
    }
    
    private func setupViews() {
        contentView.addSubview(settingLabel)
        contentView.addSubview(emailLabel)
        contentView.addSubview(usernameLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(chevronImageView)
        contentView.addSubview(profileView)
        profileView.addSubview(profileImageView)
    }
    
    private func setupConstrains() {
        settingLabel.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(StandardVerticalMargin + (StandardVerticalMargin / 2))
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
            make.height.equalTo(StandardVerticalMargin * 2)
        }
        
        emailLabel.snp.makeConstraints { make in
            make.top.equalTo(settingLabel.snp.bottom).offset(StandardVerticalMargin)
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
            make.height.equalTo(StandardVerticalMargin * 2)
        }
        
        usernameLabel.snp.makeConstraints { make in
            make.top.equalTo(emailLabel.snp.bottom).offset(StandardVerticalMargin / 2)
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
            make.height.equalTo(StandardVerticalMargin * 2)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(usernameLabel.snp.bottom).offset(StandardVerticalMargin)
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
            make.height.equalTo(StandardVerticalMargin * 2)
            make.bottom.equalTo(contentView).inset(StandardVerticalMargin + (StandardVerticalMargin / 2))
        }
        
        chevronImageView.snp.makeConstraints { make in
            make.height.equalTo(userProfileImageSize.height)
            make.width.equalTo(userProfileImageSize.width)
            make.centerY.equalTo(contentView)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
        }
        
        profileView.snp.makeConstraints { make in
            make.height.equalTo(userProfileImageSize.height)
            make.width.equalTo(userProfileImageSize.height)
            make.centerY.equalTo(contentView)
            make.trailing.equalTo(chevronImageView.snp.leading).inset(-StandardHorizontalMargin / 2)
        }
        
        profileImageView.snp.makeConstraints { make in
            make.edges.equalTo(profileView)
        }
    }
    
    private func addAccessibilityIdentifiers() {
        profileImageView.accessibilityIdentifier = "ProfileViewController:profile-image-view"
        profileImageView.accessibilityHint = Strings.accessibilityShowUserProfileHint
        profileImageView.accessibilityLabel = Strings.Accessibility.profileLabel
    }
    
    func update(username: String, email: String) {
        usernameLabel.attributedText = subtitleTextStyle.attributedString(withText: Strings.Settings.UserProfile.username(username: username))
        emailLabel.attributedText = subtitleTextStyle.attributedString(withText: Strings.Settings.UserProfile.email(email: email))
    }
}

class RestorePurchasesCell: UITableViewCell {
    static let identifier = "RestorePurchasesCell"
        
    private lazy var settingLabel: UILabel = {
        let label = UILabel()
        label.attributedText = titleTextStyle.attributedString(withText: Strings.Settings.Purchases.title)
        return label
    }()
    
    private lazy var descriptionLabel: UILabel = {
        let label = UILabel()
        label.attributedText = subtitleTextStyle.attributedString(withText: Strings.Settings.Purchases.heading)
        return label
    }()
    
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = titleTextStyle.attributedString(withText: Strings.Settings.Purchases.message)
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        accessibilityIdentifier = "ProfileViewController:restore-purchases-cell"
        
        setupViews()
        setupConstrains()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(settingLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(subtitleLabel)
    }
    
    private func setupConstrains() {
        settingLabel.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(StandardVerticalMargin + (StandardVerticalMargin / 2))
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
            make.height.equalTo(StandardVerticalMargin * 2)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(settingLabel.snp.bottom).offset(StandardVerticalMargin)
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
            make.height.equalTo(StandardVerticalMargin * 2)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(StandardVerticalMargin / 2)
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
            make.height.greaterThanOrEqualTo(StandardVerticalMargin * 2)
            make.bottom.equalTo(contentView).inset(StandardVerticalMargin + (StandardVerticalMargin / 2))
        }
    }
}

protocol HelpCellDelegate {
    func didSelectEmail()
    func didSelectFAQ()
}

class HelpCell: UITableViewCell {
    static let identifier = "HelpCell"
    
    var delegate: HelpCellDelegate?
    
    private var isFeedbackEnabled: Bool = false
    private var isFaqEnabled: Bool = false
    
    private lazy var feedbackSupportContainer = UIView()
    private lazy var faqContainer = UIView()
    
    private lazy var settingLabel: UILabel = {
        let label = UILabel()
        label.attributedText = titleTextStyle.attributedString(withText: Strings.Settings.Help.title)
        return label
    }()
    
    private lazy var buttonStyle = OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().primaryBaseColor())
    
    private lazy var feedbackLabel: UILabel = {
        let label = UILabel()
        label.attributedText = subtitleTextStyle.attributedString(withText: Strings.Settings.Help.Heading.feedback)
        return label
    }()
    
    private lazy var feedbackSubtitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = titleTextStyle.attributedString(withText: Strings.Settings.Help.Message.feedback)
        return label
    }()
    
    private lazy var emailFeedbackButton: UIButton = {
        let button = UIButton()
        button.layer.borderWidth = 1
        button.layer.borderColor = OEXStyles.shared().neutralXLight().cgColor
        button.oex_addAction({ [weak self] _ in
            self?.delegate?.didSelectEmail()
        }, for: .touchUpInside)
        
        button.setAttributedTitle(buttonStyle.attributedString(withText: Strings.Settings.Help.ButtonTitle.feedback), for: UIControl.State())
        return button
    }()
    
    private lazy var supportLabel: UILabel = {
        let label = UILabel()
        label.attributedText = subtitleTextStyle.attributedString(withText: Strings.Settings.Help.Heading.support)
        return label
    }()
    
    private lazy var supportSubtitleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = titleTextStyle.attributedString(withText: Strings.Settings.Help.Message.feedback)
        return label
    }()
    
    private lazy var viewFaqButton: UIButton = {
        let button = UIButton()
        button.layer.borderWidth = 1
        button.layer.borderColor = OEXStyles.shared().neutralXLight().cgColor
        button.oex_addAction({ [weak self] _ in
            self?.delegate?.didSelectFAQ()
        }, for: .touchUpInside)
        
        let faqButtonTitle = [buttonStyle.attributedString(withText: Strings.Settings.Help.ButtonTitle.viewFaq), faqButtonIcon]
        let attributedText = NSAttributedString.joinInNaturalLayout(attributedStrings: faqButtonTitle)
        button.setAttributedTitle(attributedText, for: UIControl.State())
        
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
        accessibilityIdentifier = "ProfileViewController:help-cell"
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func update(isFeedbackEnabled: Bool, isFaqEnabled: Bool) {
        self.isFeedbackEnabled = isFeedbackEnabled
        self.isFaqEnabled = isFaqEnabled
        setupViews()
        setupConstrains()
    }
    
    private func setupViews() {
        contentView.addSubview(settingLabel)
        
        if isFeedbackEnabled {
            feedbackSupportContainer.addSubview(feedbackLabel)
            feedbackSupportContainer.addSubview(feedbackSubtitleLabel)
            feedbackSupportContainer.addSubview(emailFeedbackButton)
            contentView.addSubview(feedbackSupportContainer)
        }
        
        if isFaqEnabled {
            faqContainer.addSubview(supportLabel)
            faqContainer.addSubview(supportSubtitleLabel)
            faqContainer.addSubview(viewFaqButton)
            contentView.addSubview(faqContainer)
        }
    }
    
    private func setupConstrains() {
        settingLabel.snp.makeConstraints { make in
            make.top.equalTo(contentView).offset(StandardVerticalMargin + (StandardVerticalMargin / 2))
            make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
            make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
            make.height.equalTo(StandardVerticalMargin * 2)
        }
        
        if isFeedbackEnabled {
            feedbackSupportContainer.snp.makeConstraints { make in
                make.top.equalTo(settingLabel.snp.bottom).offset(StandardVerticalMargin)
                make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
                make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
                
                if isFaqEnabled {
                    make.bottom.equalTo(emailFeedbackButton.snp.bottom).offset(StandardVerticalMargin)
                } else {
                    make.bottom.equalTo(contentView).inset(StandardVerticalMargin)
                }
            }
            
            feedbackLabel.snp.makeConstraints { make in
                make.top.equalTo(feedbackSupportContainer)
                make.leading.equalTo(feedbackSupportContainer)
                make.trailing.equalTo(feedbackSupportContainer)
                make.height.equalTo(StandardVerticalMargin * 2)
            }
            
            feedbackSubtitleLabel.snp.makeConstraints { make in
                make.top.equalTo(feedbackLabel.snp.bottom).offset(StandardVerticalMargin / 2)
                make.leading.equalTo(feedbackSupportContainer)
                make.trailing.equalTo(feedbackSupportContainer)
                make.height.greaterThanOrEqualTo(StandardVerticalMargin * 2)
            }
            
            emailFeedbackButton.snp.makeConstraints { make in
                make.top.equalTo(feedbackSubtitleLabel.snp.bottom).offset(StandardVerticalMargin)
                make.leading.equalTo(feedbackSupportContainer)
                make.trailing.equalTo(feedbackSupportContainer)
                make.height.equalTo(StandardVerticalMargin * 5)
                
                if !isFaqEnabled {
                    make.bottom.equalTo(feedbackSupportContainer).inset(StandardVerticalMargin)
                }
            }
        }
        
        if isFaqEnabled {
            faqContainer.snp.makeConstraints { make in
                if isFeedbackEnabled {
                    make.top.equalTo(feedbackSupportContainer.snp.bottom)
                } else {
                    make.top.equalTo(settingLabel.snp.bottom).offset(StandardVerticalMargin)
                }
                make.leading.equalTo(contentView).offset(StandardHorizontalMargin)
                make.trailing.equalTo(contentView).inset(StandardHorizontalMargin)
                make.bottom.equalTo(contentView).inset(StandardVerticalMargin)
            }
            
            supportLabel.snp.makeConstraints { make in
                make.top.equalTo(faqContainer).offset(StandardVerticalMargin)
                make.leading.equalTo(faqContainer)
                make.trailing.equalTo(faqContainer)
                make.height.equalTo(StandardVerticalMargin * 2)
            }
            
            supportSubtitleLabel.snp.makeConstraints { make in
                make.top.equalTo(supportLabel.snp.bottom).offset(StandardVerticalMargin / 2)
                make.leading.equalTo(faqContainer)
                make.trailing.equalTo(faqContainer)
                make.height.greaterThanOrEqualTo(StandardVerticalMargin * 2)
            }
            
            viewFaqButton.snp.makeConstraints { make in
                make.top.equalTo(supportSubtitleLabel.snp.bottom).offset(StandardVerticalMargin)
                make.leading.equalTo(faqContainer)
                make.trailing.equalTo(faqContainer)
                make.height.equalTo(StandardVerticalMargin * 5)
                make.bottom.equalTo(faqContainer).inset(StandardVerticalMargin + (StandardVerticalMargin / 2))
            }
        }
    }
}

protocol SignoutCellDelegate {
    func didSingout()
}

class SignOutVersionCell: UITableViewCell {
    static let identifier = "SignOutVersionCell"
    
    var delegate: SignoutCellDelegate?
    
    private lazy var signoutButton: UIButton = {
        let button = UIButton()
        button.layer.borderWidth = 1
        button.layer.borderColor = OEXStyles.shared().neutralXLight().cgColor
        button.oex_addAction({ [weak self] _ in
            self?.delegate?.didSingout()
        }, for: .touchUpInside)
        
        return button
    }()
    
    private lazy var versionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = titleTextStyle.attributedString(withText: Strings.versionDisplay(number: Bundle.main.oex_buildVersionString(), environment: ""))
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        selectionStyle = .none
        accessibilityIdentifier = "ProfileViewController:help-cell"
        
        setupViews()
        setupConstrains()
        
        let style = OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().primaryBaseColor())
        signoutButton.setAttributedTitle(style.attributedString(withText: Strings.Settings.Signout.buttonTitle), for: UIControl.State())
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
            make.height.equalTo(StandardVerticalMargin * 2)
            make.bottom.equalTo(contentView).inset(StandardVerticalMargin * 2)
        }
    }
}
