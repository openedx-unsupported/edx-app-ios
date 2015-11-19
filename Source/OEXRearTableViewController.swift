//
//  OEXRearTableController.swift
//  edX
//
//  Created by Michael Katz on 9/21/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import MessageUI


private enum OEXRearViewOptions: Int {
    case UserProfile, MyCourse, MyVideos, FindCourses, MySettings, SubmitFeeback, Debug
}

class OEXRearTableViewController : UITableViewController {
    
    struct Environment {
        let networkManager = OEXRouter.sharedRouter().environment.networkManager
        let userProfileManager = OEXRouter.sharedRouter().environment.dataManager.userProfileManager
    }
    
    var dataInterface: OEXInterface!
    
    @IBOutlet var coursesLabel: UILabel!
    @IBOutlet var videosLabel: UILabel!
    @IBOutlet var findCoursesLabel: UILabel!
    @IBOutlet var settingsLabel: UILabel!
    @IBOutlet var submitFeedbackLabel: UILabel!
    @IBOutlet var logoutButton: UIButton!
    
    @IBOutlet var userNameLabel: UILabel!
    @IBOutlet var userEmailLabel: UILabel!
    @IBOutlet var lbl_AppVersion: UILabel!
    @IBOutlet var userProfilePicture: UIImageView!
    @IBOutlet weak var cellDebug: UITableViewCell!
    
    lazy var environment = Environment()
    var profileFeed: Feed<UserProfile>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //EdX Interface
        dataInterface = OEXInterface.sharedInterface()
        
        setupProfileLoader()
        updateUIWithUserInfo()
        
        let environmentName = OEXConfig.sharedConfig().environmentName()!
        let appVersion = NSBundle.mainBundle().oex_shortVersionString()
        
        lbl_AppVersion.text = "Version \(appVersion) \(environmentName)"
        lbl_AppVersion.accessibilityLabel = lbl_AppVersion.text
        
        //UI
        logoutButton.setBackgroundImage(UIImage(named: "bt_logout_active"), forState: .Highlighted)
        
        //Listen to notification
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dataAvailable:", name: NOTIFICATION_URL_RESPONSE, object: nil)
        
        coursesLabel.text = Strings.myCourses.oex_uppercaseStringInCurrentLocale()
        videosLabel.text = Strings.myVideos.oex_uppercaseStringInCurrentLocale()
        findCoursesLabel.text = Strings.findCourses.oex_uppercaseStringInCurrentLocale()
        settingsLabel.text = Strings.mySettings.oex_uppercaseStringInCurrentLocale()
        submitFeedbackLabel.text = Strings.submitFeedback.oex_uppercaseStringInCurrentLocale()
        logoutButton.setTitle(Strings.logout.oex_uppercaseStringInCurrentLocale(), forState: .Normal)
        
        setNaturalTextAlignment()
        setAccessibilityLabels()
        
        if !OEXConfig.sharedConfig().shouldEnableProfiles() {
            //hide the profile image while not display the feature
            //there is still a little extra padding, but this will just be a temporary issue anyway
            userProfilePicture.hidden = true
            let widthConstraint = userProfilePicture.constraints.filter { $0.identifier == "profileWidth" }[0]
            let heightConstraint = userProfilePicture.constraints.filter { $0.identifier == "profileHeight" }[0]
            widthConstraint.constant = 0
            heightConstraint.constant = 85
        }

    }
    
    private func setupProfileLoader() {
        guard OEXConfig.sharedConfig().shouldEnableProfiles() else { return }
        profileFeed = self.environment.userProfileManager.feedForCurrentUser()
        profileFeed?.output.listen(self,  success: { profile in
            self.userProfilePicture.remoteImage = profile.image(self.environment.networkManager)
            }, failure : { _ in
                Logger.logError("Profiles", "Unable to fetch profile")
        })
    }
    
    private func updateUIWithUserInfo() {
        if let currentUser = OEXSession.sharedSession()?.currentUser {
            userNameLabel.text = currentUser.name
            userEmailLabel.text = currentUser.email
            profileFeed?.refresh()
        }
    }
    
    private func setNaturalTextAlignment() {
        coursesLabel.textAlignment = .Natural
        videosLabel.textAlignment = .Natural
        findCoursesLabel.textAlignment = .Natural
        settingsLabel.textAlignment = .Natural
        submitFeedbackLabel.textAlignment = .Natural
        userNameLabel.textAlignment = .Natural
        userNameLabel.adjustsFontSizeToFitWidth = true
        userEmailLabel.textAlignment = .Natural
    }
    
    private func setAccessibilityLabels() {
        userNameLabel.accessibilityLabel = userNameLabel.text
        userEmailLabel.accessibilityLabel = userEmailLabel.text
        coursesLabel.accessibilityLabel = coursesLabel.text
        videosLabel.accessibilityLabel = videosLabel.text
        findCoursesLabel.accessibilityLabel = findCoursesLabel.text
        settingsLabel.accessibilityLabel = settingsLabel.text
        submitFeedbackLabel.accessibilityLabel = submitFeedbackLabel.text
        logoutButton.accessibilityLabel = logoutButton.titleLabel!.text
        userProfilePicture.accessibilityLabel = Strings.accessibilityUserAvatar
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return OEXStyles.sharedStyles().standardStatusBarStyle()
    }
    
    override func tableView(tableView: UITableView, didHighlightRowAtIndexPath indexPath: NSIndexPath) {
        let cell = self.tableView(tableView, cellForRowAtIndexPath: indexPath)
        if let separatorImage = cell.contentView.viewWithTag(10) {
            separatorImage.hidden = true
        }
    }
    
    override func tableView(tableView: UITableView, didUnhighlightRowAtIndexPath indexPath: NSIndexPath) {
        let cell = self.tableView(tableView, cellForRowAtIndexPath: indexPath)
        if let separatorImage = cell.contentView.viewWithTag(10) {
            let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.5 * Double(NSEC_PER_SEC)))
            dispatch_after(delayTime, dispatch_get_main_queue()) {
                separatorImage.hidden = false
            }
        }
        
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if let option = OEXRearViewOptions(rawValue: indexPath.row) {
            switch option {
            case .UserProfile:
                guard OEXConfig.sharedConfig().shouldEnableProfiles() else { break }
                guard let currentUserName = OEXSession.sharedSession()?.currentUser?.username else { return }
                OEXRouter.sharedRouter().showProfileForUsername(username: currentUserName)
            case .MyCourse:
                OEXRouter.sharedRouter().showMyCourses()
            case .MyVideos:
                OEXRouter.sharedRouter().showMyVideos()
            case .FindCourses:
                OEXRouter.sharedRouter().showFindCourses()
                OEXAnalytics.sharedAnalytics().trackUserFindsCourses()
            case .MySettings:
                OEXRouter.sharedRouter().showMySettings()
            case .SubmitFeeback:
                launchEmailComposer()
            case .Debug:
                OEXRouter.sharedRouter().showDebugPane()
            }
        }
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }

    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == OEXRearViewOptions.Debug.rawValue && OEXConfig.sharedConfig().shouldShowDebug() == false {
            return 0
        }
        return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
    }
    
    @IBAction func logoutClicked(sender: UIButton) {
        // Analytics User Logout
        OEXAnalytics.sharedAnalytics().trackUserLogout()
        // Analytics tagging
        OEXAnalytics.sharedAnalytics().clearIdentifiedUser()

        sender.setBackgroundImage(UIImage(named: "bt_logout_active"), forState: .Normal)
        // Set the language to blank
        OEXInterface.setCCSelectedLanguage("")
        
        OEXInterface.sharedInterface().deactivateWithCompletionHandler() {
            OEXSession.sharedSession()?.closeAndClearSession()
            OEXRouter.sharedRouter().showLoggedOutScreen()
        }
    }
    
    func dataAvailable(notification: NSNotification) {
        let successString = notification.userInfo![NOTIFICATION_KEY_STATUS] as? String;
        let URLString = notification.userInfo![NOTIFICATION_KEY_URL] as? String;
        
        if successString == NOTIFICATION_VALUE_URL_STATUS_SUCCESS && URLString == dataInterface.URLStringForType(URL_USER_DETAILS) {
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
            mail.navigationBar.tintColor = OEXStyles.sharedStyles().navigationItemTintColor()
            mail.setSubject(Strings.customerFeedback)
            mail.setMessageBody("", isHTML: false)
            if let fbAddress = OEXConfig.sharedConfig().feedbackEmailAddress() {
                mail.setToRecipients([fbAddress])
            }
            presentViewController(mail, animated: true, completion: nil)
        }
    }
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        dismissViewControllerAnimated(true, completion: nil)
    }
}
