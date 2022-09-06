//
//  UserProfileView.swift
//  edX
//
//  Created by Akiva Leffert on 4/4/16.
//  Copyright © 2016 edX. All rights reserved.
//

class UserProfileView : UIView, UIScrollViewDelegate {
    
    private class SystemLabel: UILabel {
        override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
            return super.textRect(forBounds: bounds, limitedToNumberOfLines: numberOfLines).insetBy(dx: 10, dy: 0)
        }
        
        override func drawText(in rect: CGRect) {
            let newRect = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            super.drawText(in: rect.inset(by: newRect))
        }
    }
    
    typealias Environment =  OEXSessionProvider & OEXStylesProvider
    
    private var environment : Environment
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
    private let topContainer = UIView()
    
    init(environment: Environment, frame: CGRect) {
        self.environment = environment
        super.init(frame: frame)
        
        addSubview(scrollView)
        
        setupViews()
        setupConstraints()
        setAccessibilityIdentifiers()
    }
    
    private func setupViews() {
        topContainer.backgroundColor = .white
        
        scrollView.backgroundColor = .white
        scrollView.delegate = self
        
        avatarImage.borderWidth = 3
        avatarImage.borderColor = environment.styles.primaryBaseColor()
        topContainer.addSubview(avatarImage)
        
        usernameLabel.textColor = environment.styles.primaryBaseColor()
        usernameLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 1000), for: .vertical)
        topContainer.addSubview(usernameLabel)

        messageLabel.numberOfLines = 0
        messageLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 1000), for: .vertical)
        topContainer.addSubview(messageLabel)
        
        languageLabel.accessibilityHint = Strings.Profile.languageAccessibilityHint
        languageLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 1000), for: .vertical)
        topContainer.addSubview(languageLabel)
        
        countryLabel.accessibilityHint = Strings.Profile.countryAccessibilityHint
        countryLabel.setContentHuggingPriority(UILayoutPriority(rawValue: 1000), for: .vertical)
        topContainer.addSubview(countryLabel)
        
        bioText.backgroundColor = UIColor.clear
        bioText.textAlignment = .natural
        bioText.isScrollEnabled = false
        bioText.isEditable = false
        bioText.textContainer.lineFragmentPadding = 0;
        bioText.textContainerInset = UIEdgeInsets.zero
        
        tabs.layoutMargins = UIEdgeInsets(top: StandardHorizontalMargin, left: StandardHorizontalMargin, bottom: StandardHorizontalMargin, right: StandardHorizontalMargin)
        
        tabs.items = [bioTab]
        scrollView.addSubview(topContainer)
        scrollView.addSubview(tabs)
        
        bottomBackground.backgroundColor = .clear
        scrollView.insertSubview(bottomBackground, belowSubview: tabs)
        
        bioSystemMessage.isHidden = true
        bioSystemMessage.numberOfLines = 0
        bioSystemMessage.backgroundColor = .clear
        scrollView.insertSubview(bioSystemMessage, aboveSubview: tabs)
        
        header.style = .lightContent
        header.backgroundColor = .clear
        header.isHidden = true
        addSubview(header)
        
        bottomBackground.backgroundColor = .clear
    }
    
    private func setAccessibilityIdentifiers() {
        accessibilityIdentifier = "UserProfileView:"
        scrollView.accessibilityIdentifier = "UserProfileView:scroll-view"
        usernameLabel.accessibilityIdentifier = "UserProfileView:username-label"
        messageLabel.accessibilityIdentifier = "UserProfileView:message-label"
        countryLabel.accessibilityIdentifier = "UserProfileView:country-label"
        languageLabel.accessibilityIdentifier = "UserProfileView:language-label"
        bioText.accessibilityIdentifier = "UserProfileView:bio-text-view"
        bioSystemMessage.accessibilityIdentifier = "UserProfileView:bio-system-message-label"
        header.accessibilityIdentifier = "UserProfileView:profile-header-view"
        bottomBackground.accessibilityIdentifier = "UserProfileView:bottom-background-view"
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        topContainer.superview?.bringSubviewToFront(topContainer)
        topContainer.addShadow(offset: CGSize(width: 0, height: 2), color: environment.styles.primaryDarkColor(), radius: 2, opacity: 0.35, cornerRadius: 0)
    }
    
    private func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
        
        avatarImage.snp.makeConstraints { make in
            make.width.equalTo(avatarImage.snp.height)
            make.width.equalTo(StandardHorizontalMargin * 11)
            make.centerX.equalTo(topContainer)
            make.top.equalTo(topContainer.snp.topMargin).offset(StandardVerticalMargin * 2.5)
        }
        
        usernameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarImage.snp.bottom).offset(4)
            make.centerX.equalTo(topContainer)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(usernameLabel.snp.bottom).offset(4).priority(.high)
            make.centerX.equalTo(topContainer)
        }
        
        languageLabel.snp.makeConstraints { make in
            make.top.equalTo(messageLabel.snp.bottom)
            make.centerX.equalTo(topContainer)
        }
        
        countryLabel.snp.makeConstraints { make in
            make.top.equalTo(languageLabel.snp.bottom)
            make.centerX.equalTo(topContainer)
        }
        
        topContainer.snp.makeConstraints { make in
            make.top.equalTo(scrollView.snp.top)
            make.leading.equalTo(scrollView)
            make.trailing.equalTo(scrollView)
            make.bottom.equalTo(tabs.snp.top)
        }
        
        tabs.snp.makeConstraints { make in
            make.top.equalTo(countryLabel.snp.bottom).offset(StandardVerticalMargin * 4.3).priority(.high)
            make.bottom.equalTo(scrollView)
            make.leading.equalTo(scrollView)
            make.trailing.equalTo(scrollView)
            make.width.equalTo(scrollView)
        }
        
        bioSystemMessage.snp.makeConstraints { make in
            make.top.equalTo(tabs)
            make.bottom.greaterThanOrEqualTo(self)
            make.leading.equalTo(scrollView)
            make.trailing.equalTo(scrollView)
            make.width.equalTo(scrollView)
        }
        
        bottomBackground.snp.makeConstraints { make in
            make.edges.equalTo(bioSystemMessage)
        }
        
        header.snp.makeConstraints { make in
            make.top.equalTo(scrollView)
            make.leading.equalTo(scrollView)
            make.trailing.equalTo(scrollView)
            make.height.equalTo(StandardVerticalMargin * 7)
        }
    }
    
    private func setMessage(message: String?) {
        guard let message = message else {
            messageLabel.text = nil
            return
        }
        
        let messageStyle = OEXTextStyle(weight: .light, size: .xSmall, color: .black)
        messageLabel.attributedText = messageStyle.attributedString(withText: message)
    }
    
    private func messageForProfile(profile : UserProfile, editable : Bool) -> String? {
        if profile.sharingLimitedProfile {
            return editable ? (profile.parentalConsent == false ? Strings.Profile.showingLimited : nil) : nil
        } else {
            return nil
        }
    }
    
    private var bioTab : TabItem {
        return TabItem(name: "About", view: bioText, identifier: "bio")
    }
    
    private func setDefaultValues() {
        bioText.text = nil
        countryLabel.text = nil
        languageLabel.text = nil
    }
    
    func populateFields(profile: UserProfile, editable : Bool, networkManager : NetworkManager) {
        let usernameStyle = OEXTextStyle(weight : .normal, size: .xxLarge, color: environment.styles.primaryBaseColor())
        let infoStyle = OEXTextStyle(weight: .light, size: .xSmall, color: environment.styles.primaryBaseColor())
        let bioStyle = environment.styles.textAreaBodyStyle
        let messageStyle = OEXMutableTextStyle(weight: .bold, size: .large, color: environment.styles.primaryBaseColor())
        messageStyle.alignment = .center
        
        usernameLabel.attributedText = usernameStyle.attributedString(withText: profile.username)
        bioSystemMessage.isHidden = true
        avatarImage.remoteImage = profile.image(networkManager: networkManager)
        setDefaultValues()
        
        setMessage(message: messageForProfile(profile: profile, editable: editable))
        
        if !profile.sharingLimitedProfile {
            if let language = profile.language {
                let icon = Icon.Language.attributedText(style: infoStyle.withSize(.small))
                let langText = infoStyle.attributedString(withText: language)
                languageLabel.attributedText = NSAttributedString.joinInNaturalLayout(attributedStrings: [icon, langText])
            }
            
            if let country = profile.country {
                let icon = Icon.Country.attributedText(style: infoStyle.withSize(.small))
                let countryText = infoStyle.attributedString(withText: country)
                countryLabel.attributedText = NSAttributedString.joinInNaturalLayout(attributedStrings: [icon, countryText])
            }
            
            if let bio = profile.bio {
                bioText.attributedText = bioStyle.attributedString(withText: bio)
                bioText.isAccessibilityElement = true
                bioText.accessibilityLabel = Strings.Accessibility.Account.bioLabel
            } else {
                let message = messageStyle.attributedString(withText: Strings.Profile.noBio)
                bioSystemMessage.attributedText = message
                bioSystemMessage.isHidden = false
                let accessibilityLabelText = "\(Strings.Accessibility.Account.bioLabel), \(Strings.Profile.noBio)"
                bioSystemMessage.accessibilityLabel = accessibilityLabelText
                bioSystemMessage.isAccessibilityElement = true
                bioText.isAccessibilityElement = false
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
