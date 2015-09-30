//
//  UserProfileViewController.swift
//  edX
//
//  Created by Michael Katz on 9/22/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

public class UserProfileViewController: UIViewController {
    
    public struct Environment {
        let networkManager: NetworkManager
        
        public init(networkManager: NetworkManager) {
            self.networkManager = networkManager
        }
    }
    
    let username: String
    let profile: BackedStream<UserProfile> = BackedStream()
    var environment: Environment
    
    var avatarImage: ProfileImageView!
    var usernameLabel: UILabel!
    var messageLabel: UILabel!
    var countryLabel: UILabel!
    var languageLabel: UILabel!
    var bioText: UITextView!
    
    var header: ProfileBanner!
    
    public init(username: String, environment: Environment) {
        self.username = username
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
        addListener()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addListener() {
        profile.listen(self, success: { profile in
            self.populateFields(profile)
            }, failure : { _ in
                //TODO: do error handle in next phase with edit code
        })
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        let scrollView = UIScrollView()
        view.addSubview(scrollView)
        scrollView.backgroundColor = OEXStyles.sharedStyles().primaryBaseColor()
        scrollView.delegate = self
        
        scrollView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(view)
        }
        
        let editIcon = Icon.ProfileEdit
        let editButton = UIBarButtonItem(image: editIcon.barButtonImage(), style: .Plain, target: nil, action: nil)
        editButton.oex_setAction() {
            let editController = UserProfileEditViewController(profile: self.profile.value!)
            self.navigationController?.pushViewController(editController, animated: true)
        }
        editButton.accessibilityLabel = OEXLocalizedString("ACCESSIBILITY_EDIT_PROFILE", nil)
        navigationItem.rightBarButtonItem = editButton
    
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: Icon.Menu.barButtonImage(), style: .Plain, target: nil, action: nil)
        navigationItem.leftBarButtonItem?.oex_setAction() {
            self.revealViewController().revealToggleAnimated(true)
        }
        navigationController?.navigationBar.tintColor = OEXStyles.sharedStyles().neutralWhite()
        navigationController?.navigationBar.barTintColor = OEXStyles.sharedStyles().primaryBaseColor()
        
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

        
        let margin = 4
        
        avatarImage.snp_makeConstraints { (make) -> Void in
            make.width.equalTo(avatarImage.snp_height)
            make.width.equalTo(166)
            make.centerX.equalTo(scrollView)
            make.top.equalTo(scrollView.snp_topMargin).offset(20)
        }

        usernameLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(avatarImage.snp_bottom).offset(margin)
            make.centerX.equalTo(scrollView)
        }
        
        messageLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(usernameLabel.snp_bottom).offset(margin).priorityHigh()
            make.centerX.equalTo(scrollView)
        }

        languageLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(messageLabel.snp_bottom).offset(margin)
            make.centerX.equalTo(scrollView)
        }
        
        countryLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(languageLabel.snp_bottom).offset(margin)
            make.centerX.equalTo(scrollView)
        }

        bioText.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(countryLabel.snp_bottom).offset(margin + 6).priorityHigh()
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


        header = ProfileBanner(frame: CGRectZero)
        header.backgroundColor = scrollView.backgroundColor
        header.hidden = true
        view.addSubview(header)
        
        header.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(scrollView)
            make.leading.equalTo(scrollView)
            make.trailing.equalTo(scrollView)
            make.height.equalTo(56)
        }
        
    }

    override public func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        refreshProfile() //update with server changes
    }
    
    private func refreshProfile() {
        let profileStream = ProfileHelper.getProfile(username, networkManager: environment.networkManager)
        profile.backWithStream(profileStream)
    }
    
    private func populateFields(profile: UserProfile) {
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

            avatarImage.remoteImage = profile.image(environment.networkManager)

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
        
        header.showProfile(profile, networkManager: environment.networkManager)
    }

}

extension UserProfileViewController : UIScrollViewDelegate {
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        UIView.animateWithDuration(0.25) {
            self.header.hidden = scrollView.contentOffset.y < CGRectGetMaxY(self.avatarImage.frame)
        }
        
    }
}
