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
        override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
            return super.textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines).insetBy(dx: 10, dy: 0)
        }
        override func drawText(in rect: CGRect) {
            let newRect = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            super.drawText(in: UIEdgeInsetsInsetRect(rect, newRect))
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
        scrollView.backgroundColor = OEXStyles.shared().primaryBaseColor()
        scrollView.delegate = self

        avatarImage.borderWidth = 3.0
        scrollView.addSubview(avatarImage)

        usernameLabel.setContentHuggingPriority(1000, for: .vertical)
        scrollView.addSubview(usernameLabel)

        messageLabel.isHidden = true
        messageLabel.numberOfLines = 0
        messageLabel.setContentHuggingPriority(1000, for: .vertical)
        scrollView.addSubview(messageLabel)

        languageLabel.accessibilityHint = Strings.Profile.languageAccessibilityHint
        languageLabel.setContentHuggingPriority(1000, for: .vertical)
        scrollView.addSubview(languageLabel)

        countryLabel.accessibilityHint = Strings.Profile.countryAccessibilityHint
        countryLabel.setContentHuggingPriority(1000, for: .vertical)
        scrollView.addSubview(countryLabel)

        bioText.backgroundColor = UIColor.clear
        bioText.textAlignment = .natural
        bioText.isScrollEnabled = false
        bioText.isEditable = false
        bioText.textContainer.lineFragmentPadding = 0;
        bioText.textContainerInset = UIEdgeInsets.zero

        tabs.layoutMargins = UIEdgeInsets(top: StandardHorizontalMargin, left: StandardHorizontalMargin, bottom: StandardHorizontalMargin, right: StandardHorizontalMargin)

        tabs.items = [bioTab]
        scrollView.addSubview(tabs)

        bottomBackground.backgroundColor = bioText.backgroundColor
        scrollView.insertSubview(bottomBackground, belowSubview: tabs)

        bioSystemMessage.isHidden = true
        bioSystemMessage.numberOfLines = 0
        bioSystemMessage.backgroundColor = OEXStyles.shared().neutralXLight()
        scrollView.insertSubview(bioSystemMessage, aboveSubview: tabs)

        header.style = .LightContent
        header.backgroundColor = scrollView.backgroundColor
        header.isHidden = true
        self.addSubview(header)

        bottomBackground.backgroundColor = OEXStyles.shared().standardBackgroundColor()
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
            let messageStyle = OEXTextStyle(weight: .light, size: .xSmall, color: OEXStyles.shared().primaryXLightColor())

            messageLabel.isHidden = false
            messageLabel.snp_remakeConstraints { (make) -> Void in
                make.top.equalTo(usernameLabel.snp_bottom).offset(margin).priorityHigh()
                make.centerX.equalTo(scrollView)
            }
            countryLabel.isHidden = true
            languageLabel.isHidden = true

            messageLabel.attributedText = messageStyle.attributedString(withText: message)
        } else {
            messageLabel.isHidden = true
            messageLabel.snp_updateConstraints(closure: { (make) -> Void in
                make.height.equalTo(0)
            })

            countryLabel.isHidden = false
            languageLabel.isHidden = false

        }
    }

    private func messageForProfile(profile : UserProfile, editable : Bool) -> String? {
        if profile.sharingLimitedProfile {
            return editable ? Strings.Profile.showingLimited : Strings.Profile.learnerHasLimitedProfile(platformName: OEXConfig.shared().platformName())
        }
        else {
            return nil
        }
    }

    private var bioTab : TabItem {
        return TabItem(name: "About", view: bioText, identifier: "bio")
    }

    func populateFields(profile: UserProfile, editable : Bool, networkManager : NetworkManager) {
        let usernameStyle = OEXTextStyle(weight : .normal, size: .xxLarge, color: OEXStyles.shared().neutralWhiteT())
        let infoStyle = OEXTextStyle(weight: .light, size: .xSmall, color: OEXStyles.shared().primaryXLightColor())
        let bioStyle = OEXStyles.shared().textAreaBodyStyle
        let messageStyle = OEXMutableTextStyle(weight: .bold, size: .large, color: OEXStyles.shared().neutralDark())
        messageStyle.alignment = .center


        usernameLabel.attributedText = usernameStyle.attributedString(withText: profile.username)
        bioSystemMessage.isHidden = true

        avatarImage.remoteImage = profile.image(networkManager: networkManager)

        setMessage(message: messageForProfile(profile: profile, editable: editable))

        if profile.sharingLimitedProfile {
            if (profile.parentalConsent ?? false) && editable {
                let message = NSMutableAttributedString(attributedString: messageStyle.attributedString(withText: Strings.Profile.ageLimit))

                bioSystemMessage.attributedText = message
                bioSystemMessage.isHidden = false
            }
        } else {
            self.bioText.text = ""
            if let language = profile.language {
                let icon = Icon.Comment.attributedTextWithStyle(style: infoStyle)
                let langText = infoStyle.attributedString(withText: language)
                languageLabel.attributedText = NSAttributedString.joinInNaturalLayout(attributedStrings: [icon, langText])
            }
            if let country = profile.country {
                let icon = Icon.Country.attributedTextWithStyle(style: infoStyle)
                let countryText = infoStyle.attributedString(withText: country)
                countryLabel.attributedText = NSAttributedString.joinInNaturalLayout(attributedStrings: [icon, countryText])
            }
            if let bio = profile.bio {
                bioText.attributedText = bioStyle.attributedString(withText: bio)
            } else {
                let message = messageStyle.attributedString(withText: Strings.Profile.noBio)
                bioSystemMessage.attributedText = message
                bioSystemMessage.isHidden = false
            }
        }

        header.showProfile(profile: profile, networkManager: networkManager)
    }

    var extraTabs : [ProfileTabItem] = [] {
        didSet {
            let instantiatedTabs = extraTabs.map {tab in tab(scrollView) }
            tabs.items = [bioTab] + instantiatedTabs
        }
    }
    
    @objc func scrollViewDidScroll(_ scrollView: UIScrollView) {
        UIView.animate(withDuration: 0.25) {
            self.header.isHidden = scrollView.contentOffset.y < self.avatarImage.frame.maxY
        }
    }

    func chooseTab(identifier: String) {
        tabs.showTab(withIdentifier: identifier)
    }
}
