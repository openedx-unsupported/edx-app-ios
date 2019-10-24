//
//  StartupViewController.swift
//  edX
//
//  Created by Michael Katz on 5/16/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

private let CornerRadius:CGFloat = 2.0
private let BottomBarMargin:CGFloat = 20.0
private let BottomBarHeight:CGFloat = 90.0

class StartupViewController: UIViewController, InterfaceOrientationOverriding {

    typealias Environment = OEXRouterProvider & OEXConfigProvider & OEXAnalyticsProvider & OEXStylesProvider

    private let logoImageView = UIImageView()
    private let searchView = UIView()
    private let messageLabel = UILabel()
    fileprivate let environment: Environment
    private let bottomBar: BottomBarView
    
    init(environment: Environment) {
        self.environment = environment
        bottomBar = BottomBarView(environment: environment)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLogo()
        setupMessageLabel()
        setupSearchView()
        setupBottomBar()
        
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addAction { [weak self] _ in
            self?.view.endEditing(true)
        }
        view.addGestureRecognizer(tapGesture)

        addObservers()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        environment.analytics.trackScreen(withName: OEXAnalyticsScreenLaunch)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        bottomBar.updateContraints()
    }

    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    // MARK: - View Setup

    private func keyboardWillShow(notification: NSNotification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            if view.frame.size.height - (searchView.frame.origin.y + searchView.frame.size.height) < keyboardSize.height  {
                let difference = keyboardSize.height - (view.frame.size.height - (searchView.frame.origin.y + searchView.frame.size.height)) + StandardVerticalMargin
                view.frame.origin.y = -difference
            }
        }
    }

    private func keyboardWillHide() {
        view.frame.origin.y = 0
    }

    private func addObservers() {
        NotificationCenter.default.oex_addObserver(observer: self, name: UIResponder.keyboardDidShowNotification.rawValue) { (notification, observer, _) in
            observer.keyboardWillShow(notification: notification)
        }

        NotificationCenter.default.oex_addObserver(observer: self, name: UIResponder.keyboardWillHideNotification.rawValue) { (_, observer, _) in
            observer.keyboardWillHide()
        }
    }

    private func setupLogo() {
        let logo = UIImage(named: "logo")
        logoImageView.image = logo
        logoImageView.contentMode = .scaleAspectFit
        logoImageView.accessibilityLabel = environment.config.platformName()
        logoImageView.isAccessibilityElement = true
        logoImageView.accessibilityTraits = UIAccessibilityTraits.image
        logoImageView.accessibilityIdentifier = "StartUpViewController:logo-image-view"
        view.addSubview(logoImageView)

        logoImageView.snp.makeConstraints { make in
            make.leading.equalTo(safeLeading).offset(2*StandardHorizontalMargin)
            make.centerY.equalTo(view.snp.bottom).dividedBy(6.0)
            make.width.equalTo((logo?.size.width ?? 0) / 2)
            make.height.equalTo((logo?.size.height ?? 0) / 2)
        }
    }

    private func setupMessageLabel() {
        let labelStyle = OEXTextStyle(weight: .semiBold, size: .xxLarge, color: environment.styles.primaryBaseColor())
        messageLabel.numberOfLines = 0
        messageLabel.attributedText = labelStyle.attributedString(withText: Strings.Startup.infoMessageText)
        messageLabel.accessibilityIdentifier = "StartUpViewController:message-label"
        view.addSubview(messageLabel)
        
        messageLabel.snp.makeConstraints { make in
            make.top.equalTo(logoImageView.snp.bottom).offset(3 * StandardVerticalMargin)
            make.leading.equalTo(logoImageView)
            make.trailing.equalTo(safeTrailing).offset(-2 * StandardHorizontalMargin)
        }
    }
    
    private func setupSearchView() {
        let courseEnrollmentEnabled = environment.config.discovery.course.isEnabled
        guard courseEnrollmentEnabled ||
            environment.config.discovery.program.isEnabled else { return }
        
        view.addSubview(searchView)
        let borderStyle = BorderStyle(cornerRadius: .Size(CornerRadius), width: .Size(1), color: environment.styles.primaryBaseColor())
        searchView.applyBorderStyle(style: borderStyle)

        searchView.snp.makeConstraints { make in
            make.top.equalTo(messageLabel.snp.bottom).offset(6 * StandardVerticalMargin)
            make.leading.equalTo(messageLabel)
            make.trailing.equalTo(messageLabel)
            make.height.equalTo(45)
        }
        
        let searchIcon = Icon.Discovery.imageWithFontSize(size: 15)
        let searchImageView = UIImageView()
        searchImageView.image = searchIcon
        searchImageView.tintColor = environment.styles.primaryBaseColor()
        
        searchView.addSubview(searchImageView)
        
        searchImageView.snp.makeConstraints { make in
            make.leading.equalTo(StandardHorizontalMargin)
            make.centerY.equalTo(searchView)
            make.width.equalTo(15)
            make.height.equalTo(15)
        }
        
        let textStyle = OEXTextStyle(weight: .normal, size: .large, color: environment.styles.primaryBaseColor())
        let searchTextField = UITextField()
        searchTextField.accessibilityIdentifier = "StartUpViewController:search-textfield"
        searchTextField.delegate = self
        let placeholderText = courseEnrollmentEnabled ? Strings.searchCoursesPlaceholderText : Strings.searchProgramsPlaceholderText
        searchTextField.attributedPlaceholder = textStyle.attributedString(withText: placeholderText)
        searchTextField.textColor = environment.styles.primaryBaseColor()
        searchTextField.returnKeyType = .search
        searchTextField.defaultTextAttributes = environment.styles.textFieldStyle(with: .large, color: environment.styles.primaryBaseColor()).attributes.attributedKeyDictionary()
        searchView.addSubview(searchTextField)
        
        searchTextField.snp.makeConstraints { make in
            make.leading.equalTo(searchImageView.snp.trailing).offset(StandardHorizontalMargin)
            make.trailing.equalTo(searchView).offset(-StandardHorizontalMargin)
            make.centerY.equalTo(searchView)
        }
    }

    private func setupBottomBar() {
        view.addSubview(bottomBar)
        bottomBar.snp.makeConstraints { make in
            make.bottom.equalTo(safeBottom)
            make.leading.equalTo(safeLeading)
            make.trailing.equalTo(safeTrailing)
        }
    }

    fileprivate func showCourses(with searchQuery: String?) {
        let bottomBar = BottomBarView(environment: environment)
        environment.router?.showCourseCatalog(fromController: nil, bottomBar: bottomBar, searchQuery: searchQuery)
    }
}

public class BottomBarView: UIView, NSCopying {
    typealias Environment = OEXRouterProvider & OEXStylesProvider
    private var environment : Environment?
    private let bottomBar = TZStackView()
    private let signInButton = UIButton()
    private let registerButton = UIButton()

    init(frame: CGRect = CGRect.zero, environment:Environment?) {
        super.init(frame:frame)
        self.environment = environment
        makeBottomBar()
        addObserver()
    }
    
    func addObserver() {
        NotificationCenter.default.oex_addObserver(observer: self, name: NOTIFICATION_DYNAMIC_TEXT_TYPE_UPDATE) {(_, observer, _) in
            observer.updateContraints()
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func copy(with zone: NSZone? = nil) -> Any {
        let copy = BottomBarView(environment: environment)
        return copy
    }
    
    private func makeBottomBar() {

        bottomBar.backgroundColor = environment?.styles.standardBackgroundColor()
        let signInBorderStyle = BorderStyle(cornerRadius: .Size(CornerRadius), width: .Size(1), color: environment?.styles.primaryBaseColor())
        signInButton.applyBorderStyle(style: signInBorderStyle)
        signInButton.accessibilityIdentifier = "StartUpViewController:sign-in-button"
        
        let signinTextStyle = OEXTextStyle(weight: .normal, size: .large, color: environment?.styles.primaryBaseColor())
        signInButton.setAttributedTitle(signinTextStyle.attributedString(withText: Strings.Startup.loginText), for: .normal)
        let signInEvent = OEXAnalytics.loginEvent()
        signInButton.oex_addAction({ [weak self] _ in
            self?.showLogin()
            }, for: .touchUpInside, analyticsEvent: signInEvent)

        registerButton.backgroundColor = environment?.styles.primaryDarkColor()
        registerButton.applyBorderStyle(style: BorderStyle(cornerRadius: .Size(CornerRadius), width: .Size(0), color: nil))
        registerButton.accessibilityIdentifier = "StartUpViewController:register-button"
        let registerTextStyle = OEXTextStyle(weight: .normal, size: .large, color: environment?.styles.neutralWhite())
        registerButton.setAttributedTitle(registerTextStyle.attributedString(withText: Strings.Startup.createYourAccountText), for: .normal)
        let signUpEvent = OEXAnalytics.registerEvent(name: AnalyticsEventName.UserRegistrationClick.rawValue, displayName: AnalyticsDisplayName.CreateAccount.rawValue)
        registerButton.oex_addAction({ [weak self] _ in
            self?.showRegistration()
            }, for: .touchUpInside, analyticsEvent: signUpEvent)
    
        bottomBar.spacing = 10
        bottomBar.addArrangedSubview(registerButton)
        bottomBar.layoutMarginsRelativeArrangement = true
        bottomBar.addArrangedSubview(signInButton)
        
        addSubview(bottomBar)
        updateContraints()
    }
    
    fileprivate func updateContraints() {
        bottomBar.snp.makeConstraints { make in
            make.edges.equalTo(self)
        }
        
        if registerButton.titleLabel?.font.isPreferredSizeLarge ?? false  && !(UIDevice.current.orientation.isLandscape) {
            signInButton.snp.removeConstraints()
            registerButton.snp.removeConstraints()
            bottomBar.axis = .vertical
            bottomBar.snp.remakeConstraints { make in
                make.edges.equalTo(self)
            }
        } else {
            bottomBar.axis = .horizontal
            bottomBar.snp.remakeConstraints { make in
                make.edges.equalTo(self)
                make.height.equalTo(BottomBarHeight)
            }
            
            signInButton.snp.makeConstraints { make in
                make.top.equalTo(bottomBar).offset(BottomBarMargin)
                make.bottom.equalTo(bottomBar).offset(-BottomBarMargin)
                make.trailing.equalTo(bottomBar).offset(-BottomBarMargin)
                make.width.equalTo(95)
            }
            
            registerButton.snp.makeConstraints { make in
                make.top.equalTo(bottomBar).offset(BottomBarMargin)
                make.bottom.equalTo(bottomBar).offset(-BottomBarMargin)
                make.leading.equalTo(bottomBar).offset(BottomBarMargin)
                make.trailing.equalTo(signInButton.snp.leading).offset(-BottomBarMargin)
            }
        }
    }
    
    //MARK: - Actions
    func showLogin() {
        environment?.router?.showLoginScreen(from: firstAvailableUIViewController(), completion: nil)
    }
    
    func showRegistration() {
        environment?.router?.showSignUpScreen(from: firstAvailableUIViewController(), completion: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

extension StartupViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        environment.analytics.trackCourseSearch(search: textField.text ?? "", action: "landing_screen")
        showCourses(with: textField.text)
        textField.text = nil
        return true
    }
}
