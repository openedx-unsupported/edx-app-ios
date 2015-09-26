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

    
    init(profile: UserProfile) {
        self.profile = profile
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let editIcon = Icon.ProfileEdit
        let editButton = UIBarButtonItem(image: editIcon.barButtonImage(), style: .Plain, target: self, action: "edit")
        navigationItem.rightBarButtonItem = editButton
    
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: Icon.Menu.barButtonImage(), style: .Plain, target: self, action: "back:")
        navigationController?.navigationBar.tintColor = OEXStyles.sharedStyles().neutralWhite()
        navigationController?.navigationBar.barTintColor = OEXStyles.sharedStyles().primaryDarkColor()
        
        view.backgroundColor = OEXStyles.sharedStyles().primaryDarkColor()
        
        avatarImage = ProfileImageView()
        view.addSubview(avatarImage)

        usernameLabel = UILabel()
        view.addSubview(usernameLabel)
        
        languageLabel = UILabel()
        view.addSubview(languageLabel)
        countryLabel = UILabel()
        view.addSubview(countryLabel)
        
        avatarImage.snp_makeConstraints { (make) -> Void in
            make.width.equalTo(avatarImage.snp_height)
            make.width.equalTo(166)
            make.centerX.equalTo(view)
            make.top.equalTo(view.snp_topMargin).offset(20)
        }
        
        usernameLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(avatarImage.snp_bottom)
            make.centerX.equalTo(view)
        }
        
        languageLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(usernameLabel.snp_bottom)
            make.centerX.equalTo(view)
        }
        
        countryLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(languageLabel.snp_bottom)
            make.centerX.equalTo(view)
        }
        
        
//        let stackview = OA
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        populateFields()
    }
    
    private func populateFields() {
        let usernameStyle = OEXTextStyle(weight : .Normal, size: .XXLarge, color: OEXStyles.sharedStyles().neutralWhiteT())
        let infoStyle = OEXTextStyle(weight: .Light, size: .XSmall, color: OEXStyles.sharedStyles().primaryXLightColor())

        usernameLabel.attributedText = usernameStyle.attributedStringWithText(profile.username ?? "marco")
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
        
        
        //TODO: a11y
    }

    func edit() {
        
    }
    
    func back(sender: UIControl) {
        revealViewController().revealToggleAnimated(true)
    }

}
/*
user name - white xx-large
Location & language - blue x-light, x-small
content x-dark base
image is 166dip in diameter, white border is 3dip wide (1 dip = 1px @1x)
*/