//
//  UserProfileViewController.swift
//  edX
//
//  Created by Michael Katz on 9/22/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class UserProfileViewController: UIViewController {
    
    struct UserProfileViewControllerEnvironment {
        let networkManager: NetworkManager
    }
    
    var profile: UserProfile!
    var environment: UserProfileViewControllerEnvironment!
    
    var avatarImage: ProfileImageView!
    var usernameLabel: UILabel!
    var messageLabel: UILabel!
    var countryLabel: UILabel!
    var languageLabel: UILabel!
    var bioText: UITextView!
    
    var header: UIView!
    var shortProfView: ProfileImageView!
    var headerUsername: UILabel!
    
    init(profile: UserProfile, environment: UserProfileViewControllerEnvironment) {
        self.profile = profile
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let scrollView = UIScrollView()
        view.addSubview(scrollView)
        scrollView.backgroundColor = OEXStyles.sharedStyles().primaryDarkColor()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.delegate = self
        
        scrollView.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(view)
            make.left.equalTo(view)
            make.right.equalTo(view)
            make.bottom.equalTo(view)
        }
        
        let editIcon = Icon.ProfileEdit
        let editButton = UIBarButtonItem(image: editIcon.barButtonImage(), style: .Plain, target: self, action: "edit")
        editButton.accessibilityLabel = OEXLocalizedString("ACCESSIBILITY_EDIT_PROFILE", nil)
        navigationItem.rightBarButtonItem = editButton
    
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: Icon.Menu.barButtonImage(), style: .Plain, target: self, action: "back:")
        navigationController?.navigationBar.tintColor = OEXStyles.sharedStyles().neutralWhite()
        navigationController?.navigationBar.barTintColor = OEXStyles.sharedStyles().primaryDarkColor()
        
        avatarImage = ProfileImageView()
        avatarImage.borderWidth = 3.0
        scrollView.addSubview(avatarImage)

        usernameLabel = UILabel()
        usernameLabel.setContentHuggingPriority(1000, forAxis: .Vertical)
        scrollView.addSubview(usernameLabel)
        
        messageLabel = UILabel()
        messageLabel.hidden = true
        messageLabel.numberOfLines = 0
        messageLabel.setContentHuggingPriority(1000, forAxis: .Vertical)
        scrollView.addSubview(messageLabel)
        
        languageLabel = UILabel()
        languageLabel.accessibilityHint = OEXLocalizedString("ACCESSIBILITY_PROFILE_LANGUAGE_HINT", nil)
        languageLabel.setContentHuggingPriority(1000, forAxis: .Vertical)
        scrollView.addSubview(languageLabel)

        countryLabel = UILabel()
        countryLabel.accessibilityHint = OEXLocalizedString("ACCESSIBILITY_PROFILE_COUNTRY_HINT", nil)
        countryLabel.setContentHuggingPriority(1000, forAxis: .Vertical)
        scrollView.addSubview(countryLabel)
        
        bioText = UITextView()
        bioText.backgroundColor = OEXStyles.sharedStyles().neutralWhiteT()
        bioText.textAlignment = .Natural
        bioText.scrollEnabled = false
        scrollView.addSubview(bioText)
        
        let whiteSpace = UIView()
        whiteSpace.backgroundColor = bioText.backgroundColor
        scrollView.insertSubview(whiteSpace, belowSubview: bioText)

        avatarImage.snp_makeConstraints { (make) -> Void in
            make.width.equalTo(avatarImage.snp_height)
            make.width.equalTo(166)
            make.centerX.equalTo(scrollView)
            make.top.equalTo(scrollView.snp_topMargin).offset(20)
        }

        usernameLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(avatarImage.snp_bottom)
            make.centerX.equalTo(scrollView)
        }
        
        messageLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(usernameLabel.snp_bottom).priorityHigh()
            make.centerX.equalTo(scrollView)
        }

        languageLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(messageLabel.snp_bottom)
            make.centerX.equalTo(scrollView)
        }
        
        countryLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(languageLabel.snp_bottom)
            make.centerX.equalTo(scrollView)
        }

        bioText.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(countryLabel.snp_bottom).offset(6).priorityHigh()
            make.bottom.equalTo(scrollView)
            make.leading.equalTo(scrollView)
            make.trailing.equalTo(scrollView)
            make.width.equalTo(scrollView)
        }
        
        whiteSpace.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(bioText)
            make.bottom.greaterThanOrEqualTo(view)
            make.leading.equalTo(bioText)
            make.trailing.equalTo(bioText)
            make.width.equalTo(bioText)
        }


        header = UIView(frame: CGRectZero)
        header.backgroundColor = scrollView.backgroundColor
        header.hidden = true
        view.addSubview(header)
        
        header.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(scrollView)
            make.leading.equalTo(scrollView)
            make.trailing.equalTo(scrollView)
            make.height.equalTo(56)
        }
        
        shortProfView = ProfileImageView()
        header.addSubview(shortProfView)
        shortProfView.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(header.snp_leadingMargin)
            make.height.equalTo(40)
            make.width.equalTo(shortProfView.snp_height)
            make.centerY.equalTo(header)
        }
        
        headerUsername = UILabel()
        header.addSubview(headerUsername)
        headerUsername.snp_makeConstraints { (make) -> Void in
            make.leading.equalTo(shortProfView.snp_trailing).offset(6)
            make.centerY.equalTo(shortProfView)
        }
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        populateFields()
        refreshProfile() //update with server changes
    }
    
    private func refreshProfile() {
        ProfileHelper.getProfile(profile.username!, networkManager: environment.networkManager) { result in
            if let profile = result.data {
                self.profile = profile
                dispatch_async(dispatch_get_main_queue()) { self.populateFields() }
            }
        }

    }
    
    private func populateFields() {
        let usernameStyle = OEXTextStyle(weight : .Normal, size: .XXLarge, color: OEXStyles.sharedStyles().neutralWhiteT())
        let infoStyle = OEXTextStyle(weight: .Light, size: .XSmall, color: OEXStyles.sharedStyles().primaryXLightColor())
        let bioStyle = OEXStyles.sharedStyles().textAreaBodyStyle


        usernameLabel.attributedText = usernameStyle.attributedStringWithText(profile.username)

        if profile.sharingLimitedProfile {
            messageLabel.hidden = false
            countryLabel.hidden = true
            languageLabel.hidden = true
            
            messageLabel.attributedText = infoStyle.attributedStringWithText(OEXLocalizedString("PROFILE_SHOWING_LIMITED", nil))
            let newStyle = bioStyle.mutableCopy() as! OEXMutableTextStyle
            newStyle.alignment = .Center
            bioText.attributedText = newStyle.attributedStringWithText(OEXLocalizedString("PROFILE_UNDER_13", nil))
        } else {
            languageLabel.hidden = true
            countryLabel.hidden = false
            languageLabel.hidden = false

            avatarImage.remoteImage = profile.image

            if let language = profile.language {
                let icon = Icon.Comment.attributedTextWithStyle(infoStyle)
                let langText = infoStyle.attributedStringWithText(language)
                languageLabel.attributedText = NSAttributedString.joinInNaturalLayout([icon, langText])
            }
            if let country = profile.country {
                let icon = Icon.Country.attributedTextWithStyle(infoStyle)
                let countryText = infoStyle.attributedStringWithText(country)
                countryLabel.attributedText = NSAttributedString.joinInNaturalLayout([icon, countryText])
            }
            let bio = profile.bio ?? OEXLocalizedString("PROFILE_NO_BIO", nil)
            bioText.attributedText = bioStyle.attributedStringWithText(bio)
        }
        
        shortProfView.remoteImage = profile.image
        headerUsername.attributedText = usernameStyle.attributedStringWithText(profile.username)
    }

    func edit() {
        
    }
    
    func back(sender: UIControl) {
        revealViewController().revealToggleAnimated(true)
    }

}

extension UserProfileViewController : UIScrollViewDelegate {
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        UIView.animateWithDuration(0.25) {
            self.header.hidden = scrollView.contentOffset.y < CGRectGetMaxY(self.avatarImage.frame)
        }
        
    }
}
