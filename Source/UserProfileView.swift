//
//  UserProfileView.swift
//  edX
//
//  Created by Akiva Leffert on 4/4/16.
//  Copyright © 2016 edX. All rights reserved.
//

class UserProfileView : UIView, UIScrollViewDelegate {

    private let margin = 4

    private class SystemLabel: UILabel {
        private override func textRectForBounds(bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
            return CGRectInset(super.textRectForBounds(bounds, limitedToNumberOfLines: numberOfLines), 10, 0)
        }
        private override func drawTextInRect(rect: CGRect) {
            let newRect = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            super.drawTextInRect(UIEdgeInsetsInsetRect(rect, newRect))
        }
    }

    private let scrollView = UIScrollView()
    private let usernameLabel = UILabel()
    private let messageLabel = UILabel()
    private let countryLabel = UILabel()
    private let languageLabel = UILabel()
    private let bioText = UITextView()
    private let tabs = TabContainerView()
    private let bioSystemMessage = SystemLabel()
    private let avatarImage = ProfileImageView()
    private let header = ProfileBanner()
    private let bottomBackground = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(scrollView)

        setupViews()
        setupConstraints()
    }

    private func setupViews() {
        scrollView.backgroundColor = OEXStyles.sharedStyles().primaryBaseColor()
        scrollView.delegate = self

        avatarImage.borderWidth = 3.0
        scrollView.addSubview(avatarImage)

        usernameLabel.setContentHuggingPriority(1000, forAxis: .Vertical)
        scrollView.addSubview(usernameLabel)

        messageLabel.hidden = true
        messageLabel.numberOfLines = 0
        messageLabel.setContentHuggingPriority(1000, forAxis: .Vertical)
        scrollView.addSubview(messageLabel)

        languageLabel.accessibilityHint = Strings.Profile.languageAccessibilityHint
        languageLabel.setContentHuggingPriority(1000, forAxis: .Vertical)
        scrollView.addSubview(languageLabel)

        countryLabel.accessibilityHint = Strings.Profile.countryAccessibilityHint
        countryLabel.setContentHuggingPriority(1000, forAxis: .Vertical)
        scrollView.addSubview(countryLabel)

        bioText.backgroundColor = UIColor.clearColor()
        bioText.textAlignment = .Natural
        bioText.scrollEnabled = false
        bioText.editable = false
        bioText.textContainer.lineFragmentPadding = 0;
        bioText.textContainerInset = UIEdgeInsetsZero

        tabs.layoutMargins = UIEdgeInsets(top: StandardHorizontalMargin, left: StandardHorizontalMargin, bottom: StandardHorizontalMargin, right: StandardHorizontalMargin)

        tabs.items = [
            TabContainerView.Item(name: "About", view: bioText, identifier: "bio")
        ]
        scrollView.addSubview(tabs)

        bottomBackground.backgroundColor = bioText.backgroundColor
        scrollView.insertSubview(bottomBackground, belowSubview: tabs)

        bioSystemMessage.hidden = true
        bioSystemMessage.numberOfLines = 0
        bioSystemMessage.backgroundColor = OEXStyles.sharedStyles().neutralXLight()
        scrollView.insertSubview(bioSystemMessage, aboveSubview: tabs)

        header.style = .LightContent
        header.backgroundColor = scrollView.backgroundColor
        header.hidden = true
        self.addSubview(header)

        bottomBackground.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupConstraints() {
        scrollView.snp_makeConstraints { (make) -> Void in
            make.edges.equalTo(self)
        }
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
            make.top.equalTo(messageLabel.snp_bottom)
            make.centerX.equalTo(scrollView)
        }

        countryLabel.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(languageLabel.snp_bottom)
            make.centerX.equalTo(scrollView)
        }

        tabs.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(countryLabel.snp_bottom).offset(35).priorityHigh()
            make.bottom.equalTo(scrollView)
            make.leading.equalTo(scrollView)
            make.trailing.equalTo(scrollView)
            make.width.equalTo(scrollView)
        }

        bioSystemMessage.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(tabs)
            make.bottom.greaterThanOrEqualTo(self)
            make.leading.equalTo(scrollView)
            make.trailing.equalTo(scrollView)
            make.width.equalTo(scrollView)
        }

        bottomBackground.snp_makeConstraints {make in
            make.edges.equalTo(bioSystemMessage)
        }

        header.snp_makeConstraints { (make) -> Void in
            make.top.equalTo(scrollView)
            make.leading.equalTo(scrollView)
            make.trailing.equalTo(scrollView)
            make.height.equalTo(56)
        }
    }

    private func setMessage(message: String?) {
        if let message = message {
            let messageStyle = OEXTextStyle(weight: .Light, size: .XSmall, color: OEXStyles.sharedStyles().primaryXLightColor())

            messageLabel.hidden = false
            messageLabel.snp_remakeConstraints { (make) -> Void in
                make.top.equalTo(usernameLabel.snp_bottom).offset(margin).priorityHigh()
                make.centerX.equalTo(scrollView)
            }
            countryLabel.hidden = true
            languageLabel.hidden = true

            messageLabel.attributedText = messageStyle.attributedStringWithText(message)
        } else {
            messageLabel.hidden = true
            messageLabel.snp_updateConstraints(closure: { (make) -> Void in
                make.height.equalTo(0)
            })

            countryLabel.hidden = false
            languageLabel.hidden = false

        }
    }

    private func messageForProfile(profile : UserProfile, editable : Bool) -> String? {
        if profile.sharingLimitedProfile {
            return editable ? Strings.Profile.showingLimited : Strings.Profile.learnerHasLimitedProfile(platformName: OEXConfig.sharedConfig().platformName())
        }
        else {
            return nil
        }
    }

    func populateFields(profile: UserProfile, editable : Bool, networkManager : NetworkManager) {
        let usernameStyle = OEXTextStyle(weight : .Normal, size: .XXLarge, color: OEXStyles.sharedStyles().neutralWhiteT())
        let infoStyle = OEXTextStyle(weight: .Light, size: .XSmall, color: OEXStyles.sharedStyles().primaryXLightColor())
        let bioStyle = OEXStyles.sharedStyles().textAreaBodyStyle
        let messageStyle = OEXMutableTextStyle(weight: .Bold, size: .Large, color: OEXStyles.sharedStyles().neutralDark())
        messageStyle.alignment = .Center


        usernameLabel.attributedText = usernameStyle.attributedStringWithText(profile.username)
        bioSystemMessage.hidden = true

        avatarImage.remoteImage = profile.image(networkManager)

        setMessage(messageForProfile(profile, editable: editable))

        if profile.sharingLimitedProfile {
            if (profile.parentalConsent ?? false) && editable {
                let message = NSMutableAttributedString(attributedString: messageStyle.attributedStringWithText(Strings.Profile.ageLimit))

                bioSystemMessage.attributedText = message
                bioSystemMessage.hidden = false
            }
        } else {
            self.bioText.text = ""
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
            if let bio = profile.bio {
                bioText.attributedText = bioStyle.attributedStringWithText(bio)
            } else {
                let message = messageStyle.attributedStringWithText(Strings.Profile.noBio)
                bioSystemMessage.attributedText = message
                bioSystemMessage.hidden = false
            }
        }

        header.showProfile(profile, networkManager: networkManager)
    }
    
    @objc func scrollViewDidScroll(scrollView: UIScrollView) {
        UIView.animateWithDuration(0.25) {
            self.header.hidden = scrollView.contentOffset.y < CGRectGetMaxY(self.avatarImage.frame)
        }
    }
}