//
//  OEXRearTableController.swift
//  edX
//
//  Created by Michael Katz on 9/21/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import MessageUI

import edXCore

private enum OEXRearViewOptions: Int {
    case UserProfile, MyCourse, MyVideos, MySettings, SubmitFeedback, Debug, Logout
}

private let LogoutCellDefaultHeight: CGFloat = 130.0
private let versionButtonStyle = OEXTextStyle(weight:.normal, size:.xxSmall, color: OEXStyles.shared().neutralWhite())

class OEXRearTableViewController : UITableViewController {

    // TODO replace this with a proper injection when we nuke the storyboard
    struct Environment {
        let analytics = OEXRouter.shared().environment.analytics
        let config = OEXRouter.shared().environment.config
        let interface = OEXRouter.shared().environment.interface
        let networkManager = OEXRouter.shared().environment.networkManager
        let session = OEXRouter.shared().environment.session
        let userProfileManager = OEXRouter.shared().environment.dataManager.userProfileManager
        weak var router = OEXRouter.shared()
    }
    
    @IBOutlet var coursesLabel: UILabel!
    @IBOutlet var videosLabel: UILabel!
    @IBOutlet var settingsLabel: UILabel!
    @IBOutlet var submitFeedbackLabel: UILabel!
    @IBOutlet var logoutButton: UIButton!
    
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var userEmailLabel: UILabel!

    @IBOutlet var userProfilePicture: UIImageView!
    @IBOutlet weak var appVersionButton: UIButton!
    
    lazy var environment = Environment()
    var profileFeed: Feed<UserProfile>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupProfileLoader()
        updateUIWithUserInfo()
        
        let environmentName = self.environment.config.environmentName()
        let appVersion = Bundle.main.oex_buildVersionString()
        appVersionButton.setAttributedTitle(versionButtonStyle.attributedString(withText: Strings.versionDisplay(number: appVersion, environment: environmentName)), for:.normal)
        appVersionButton.accessibilityTraits = UIAccessibilityTraitStaticText
        
        //UI
        logoutButton.setBackgroundImage(UIImage(named: "bt_logout_active"), for: .highlighted)
        
        //Listen to notification
        NotificationCenter.default.addObserver(self, selector: #selector(OEXRearTableViewController.dataAvailable(notification:)), name: NSNotification.Name(rawValue: NOTIFICATION_URL_RESPONSE), object: nil)
        
        coursesLabel.text = Strings.myCourses.oex_uppercaseStringInCurrentLocale()
        videosLabel.text = Strings.myVideos.oex_uppercaseStringInCurrentLocale()
        settingsLabel.text = Strings.mySettings.oex_uppercaseStringInCurrentLocale()
        submitFeedbackLabel.text = Strings.SubmitFeedback.optionTitle.oex_uppercaseStringInCurrentLocale()
        logoutButton.setTitle(Strings.logout.oex_uppercaseStringInCurrentLocale(), for: .normal)
        
        setNaturalTextAlignment()
        setAccessibilityLabels()
        
        if !environment.config.profilesEnabled {
            //hide the profile image while not display the feature
            //there is still a little extra padding, but this will just be a temporary issue anyway
            userProfilePicture.isHidden = true
            let widthConstraint = userProfilePicture.constraints.filter { $0.identifier == "profileWidth" }[0]
            let heightConstraint = userProfilePicture.constraints.filter { $0.identifier == "profileHeight" }[0]
            widthConstraint.constant = 0
            heightConstraint.constant = 85
        }

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let profileCell = tableView.cellForRow(at: IndexPath(row: OEXRearViewOptions.UserProfile.rawValue, section: 0)) {
            profileCell.accessibilityLabel = Strings.Accessibility.LeftDrawer.profileLabel(userName: environment.session.currentUser?.name ?? "", userEmail: environment.session.currentUser?.email ?? "")
            profileCell.accessibilityHint = Strings.Accessibility.LeftDrawer.profileHint
        }
    }
    
    private func setupProfileLoader() {
        guard environment.config.profilesEnabled else { return }
        profileFeed = self.environment.userProfileManager.feedForCurrentUser()
        profileFeed?.output.listen(self,  success: { profile in
            self.userProfilePicture.remoteImage = profile.image(networkManager: self.environment.networkManager)
            }, failure : { _ in
                Logger.logError("Profiles", "Unable to fetch profile")
        })
    }
    
    private func updateUIWithUserInfo() {
        if let currentUser = environment.session.currentUser {
            userNameLabel.text = currentUser.name
            userEmailLabel.text = currentUser.email
            profileFeed?.refresh()
        }
    }
    
    private func setNaturalTextAlignment() {
        coursesLabel.textAlignment = .natural
        videosLabel.textAlignment = .natural
        settingsLabel.textAlignment = .natural
        submitFeedbackLabel.textAlignment = .natural
        userNameLabel.textAlignment = .natural
        userNameLabel.adjustsFontSizeToFitWidth = true
        userEmailLabel.textAlignment = .natural
    }
    
    private func setAccessibilityLabels() {
        userNameLabel.accessibilityLabel = userNameLabel.text
        userEmailLabel.accessibilityLabel = userEmailLabel.text
        coursesLabel.accessibilityLabel = coursesLabel.text
        videosLabel.accessibilityLabel = videosLabel.text
        settingsLabel.accessibilityLabel = settingsLabel.text
        submitFeedbackLabel.accessibilityLabel = submitFeedbackLabel.text
        logoutButton.accessibilityLabel = logoutButton.titleLabel!.text
        userProfilePicture.accessibilityLabel = Strings.accessibilityUserAvatar
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return OEXStyles.shared().standardStatusBarStyle()
    }
    
    override func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        
        let cell = tableView.cellForRow(at: indexPath)
        
        if let separatorImage = cell?.contentView.viewWithTag(10) {
            separatorImage.isHidden = true
        }
    }
    
    override func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {
        
        let cell = self.tableView.cellForRow(at: indexPath)
        if let separatorImage = cell?.contentView.viewWithTag(10) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                separatorImage.isHidden = false
            }
        }
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let option = OEXRearViewOptions(rawValue: indexPath.row) {
            switch option {
            case .UserProfile:
                guard environment.config.profilesEnabled else { break }
                guard let currentUserName = environment.session.currentUser?.username else { return }
                environment.router?.showProfileForUsername(username: currentUserName)
            case .MyCourse:
                environment.router?.showMyCourses()
            case .MyVideos:
                environment.router?.showMyVideos()
            case .MySettings:
                environment.router?.showMySettings()
            case .SubmitFeedback:
                launchEmailComposer()
            case .Debug:
                environment.router?.showDebugPane()
            case .Logout:
                break
            }
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        if ((indexPath.row == OEXRearViewOptions.Debug.rawValue && !environment.config.shouldShowDebug()) || (indexPath.row == OEXRearViewOptions.MyVideos.rawValue && !environment.config.isMyVideosEnabled)) {
            return 0
        }
        else if indexPath.row == OEXRearViewOptions.Logout.rawValue {
            let screenHeight = UIScreen.main.bounds.height
            let tableviewHeight = tableView.contentSize.height
            return max((screenHeight - tableviewHeight) + LogoutCellDefaultHeight, LogoutCellDefaultHeight)
        }
        
        
        return super.tableView(tableView, heightForRowAt: indexPath)
    }
    
    @IBAction func logoutClicked(sender: UIButton) {
        OEXFileUtility.nukeUserPIIData()
        self.environment.router?.logout()
    }
    
    func dataAvailable(notification: NSNotification) {
        let successString = notification.userInfo![NOTIFICATION_KEY_STATUS] as? String;
        let URLString = notification.userInfo![NOTIFICATION_KEY_URL] as? String;
        
        if successString == NOTIFICATION_VALUE_URL_STATUS_SUCCESS && URLString == environment.interface?.urlString(forType: URL_USER_DETAILS) {
            updateUIWithUserInfo()
        }
    }
}

extension OEXRearTableViewController : MFMailComposeViewControllerDelegate {

    func launchEmailComposer() {
        if !MFMailComposeViewController.canSendMail() {
            let alert = UIAlertView(title: Strings.emailAccountNotSetUpTitle,
                message: Strings.emailAccountNotSetUpMessage,
                delegate: nil,
                cancelButtonTitle: Strings.ok)
            alert.show()
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
