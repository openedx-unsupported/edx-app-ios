//
//  UserProfileViewController.swift
//  edX
//
//  Created by Michael Katz on 9/22/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import UIKit

class UserProfileViewController: UIViewController {
    
    var profile: UserProfile!
    
    var avatarImage: ProfileImageView!
    var usernameLabel: UILabel!
    var countryLabel: UILabel!
    var languageLabel: UILabel!
    var bioText: UITextView!
    
    var header: UIView!
    var shortProfView: ProfileImageView!
    var headerUsername: UILabel!
    
    init(profile: UserProfile) {
        self.profile = profile
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    //todo:enabler setting
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
        scrollView.addSubview(usernameLabel)
        
        languageLabel = UILabel()
        languageLabel.accessibilityHint = OEXLocalizedString("ACCESSIBILITY_PROFILE_LANGUAGE_HINT", nil)
        scrollView.addSubview(languageLabel)

        countryLabel = UILabel()
        countryLabel.accessibilityHint = OEXLocalizedString("ACCESSIBILITY_PROFILE_COUNTRY_HINT", nil)
        scrollView.addSubview(countryLabel)
        
        bioText = UITextView()
        bioText.backgroundColor = OEXStyles.sharedStyles().neutralWhiteT()
        bioText.textAlignment = .Natural
        bioText.scrollEnabled = false
        scrollView.addSubview(bioText)

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

        languageLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(usernameLabel.snp_bottom)
            make.centerX.equalTo(scrollView)
        }
        
        countryLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(languageLabel.snp_bottom)
            make.centerX.equalTo(scrollView)
        }

        bioText.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(countryLabel.snp_bottom).offset(6)
            make.bottom.equalTo(scrollView)
            make.leading.equalTo(scrollView)
            make.trailing.equalTo(scrollView)
            make.width.equalTo(scrollView)
        }

        header = UIView(frame: CGRectZero)
        header.backgroundColor = scrollView.backgroundColor
        header.hidden = true
        view.addSubview(header)
        
        header.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(scrollView)
            make.leading.equalTo(scrollView)
            make.trailing.equalTo(scrollView)
            make.height.equalTo(50)
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
    }
    
    private func populateFields() {
        let usernameStyle = OEXTextStyle(weight : .Normal, size: .XXLarge, color: OEXStyles.sharedStyles().neutralWhiteT())
        let infoStyle = OEXTextStyle(weight: .Light, size: .XSmall, color: OEXStyles.sharedStyles().primaryXLightColor())

        usernameLabel.attributedText = usernameStyle.attributedStringWithText(profile.username)
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
        
        let bioStyle = OEXStyles.sharedStyles().textAreaBodyStyle
        bioText.attributedText = bioStyle.attributedStringWithText(profile.bio)
        
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
