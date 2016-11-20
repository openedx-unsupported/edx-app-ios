//
//  StartupViewController.swift
//  edX
//
//  Created by Michael Katz on 5/16/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

class StartupViewController: UIViewController, InterfaceOrientationOverriding {

    typealias Environment = protocol<OEXRouterProvider, OEXConfigProvider>

    private let logoImageView = UIImageView()

    private let environment: Environment

    init(environment: Environment) {
        self.environment = environment

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupBackground()
        setupLogo()
        setupDiscoverButtons()
        setupBottomBar()
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        OEXAnalytics.sharedAnalytics().trackScreenWithName("launch")
    }

    override func shouldAutorotate() -> Bool {
        return false
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .Portrait
    }
    
    // MARK: - View Setup

    private func setupBackground() {
        let backgroundImage = UIImage(named: "launchBackground")
        let backgroundImageView = UIImageView(image: backgroundImage)
        backgroundImageView.contentMode = .ScaleAspectFill
        view.addSubview(backgroundImageView)

        backgroundImageView.snp_makeConstraints { (make) in
            make.edges.equalTo(view)
        }
    }

    private func setupLogo() {
        let logo = UIImage(named: "logo")
        logoImageView.image = logo
        logoImageView.contentMode = .ScaleAspectFit
        logoImageView.accessibilityLabel = environment.config.platformName()
        logoImageView.isAccessibilityElement = true
        logoImageView.accessibilityTraits = UIAccessibilityTraitImage
        view.addSubview(logoImageView)

        logoImageView.snp_makeConstraints { (make) in
            make.centerY.equalTo(view.snp_bottom).dividedBy(5.0)
            make.centerX.equalTo(view.snp_centerX)
        }
    }

    private func setupDiscoverButtons() {

        let discoverButton = UIButton()
        discoverButton.applyButtonStyle(OEXStyles.sharedStyles().filledPrimaryButtonStyle, withTitle: Strings.Startup.discovercourses)
        let discoverEvent = OEXAnalytics.discoverCoursesEvent()
        discoverButton.oex_addAction({ [weak self] _ in
            self?.showCourses()
            }, forEvents: .TouchUpInside, analyticsEvent: discoverEvent)

        view.addSubview(discoverButton)


        let exploreButton = UIButton()
        exploreButton.applyButtonStyle(OEXStyles.sharedStyles().filledPrimaryButtonStyle, withTitle: Strings.Startup.exploreSubjects)
        let exploreEvent = OEXAnalytics.exploreSubjectsEvent()
        exploreButton.oex_addAction({ [weak self] _ in
            self?.exploreSubjects()
            }, forEvents: .TouchUpInside, analyticsEvent: exploreEvent)

        view.addSubview(exploreButton)

        discoverButton.snp_makeConstraints { (make) in
            make.centerY.equalTo(view.snp_centerY)
            make.leading.equalTo(view.snp_leading).offset(30)
            make.trailing.equalTo(view.snp_trailing).inset(30)
            environment.config.courseEnrollmentConfig.isCourseDiscoveryEnabled() ? make.height.equalTo(40) : make.height.equalTo(0)
        }

        exploreButton.snp_makeConstraints { (make) in
            make.centerY.equalTo(view.snp_centerY).inset(35)
            make.leading.equalTo(view.snp_leading).offset(30)
            make.trailing.equalTo(view.snp_trailing).inset(30)
            make.height.equalTo(0)
        }
    }

    private func setupBottomBar() {
        let bottomBar = BottomBarView(environment: environment)
        view.addSubview(bottomBar)
        bottomBar.snp_makeConstraints { (make) in
            make.height.equalTo(50)
            make.bottom.equalTo(view)
            make.leading.equalTo(view.snp_leading)
            make.trailing.equalTo(view.snp_trailing)
        }

    }
    
    //MARK: - Actions
    func showCourses() {
        let bottomBar = BottomBarView(environment: environment)
        environment.router?.showCourseCatalog(bottomBar)
    }
    
    func exploreSubjects() {
        let bottomBar = BottomBarView(environment: environment)
        self.environment.router?.showExploreCourses(bottomBar)
    }
}

private class BottomBarView: UIView, NSCopying {
    typealias Environment = protocol<OEXRouterProvider>
    private var environment : Environment?
    
    override init(frame: CGRect = CGRectZero) {
        super.init(frame:frame)
        makeBottomBar()
    }
    
    convenience init (environment:Environment?) {
        self.init(frame: CGRectZero)
        self.environment = environment
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc func copyWithZone(zone: NSZone) -> AnyObject {
        let copy = BottomBarView(environment: environment)
        return copy
    }
    
    private func makeBottomBar() {
        let bottomBar = UIView()
        let signInButton = UIButton()
        let registerButton = UIButton()
        let line = UIView()
        bottomBar.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.90)
        
        signInButton.setTitle(Strings.signInText, forState: .Normal)
        let signInEvent = OEXAnalytics.loginEvent()
        signInButton.oex_addAction({ [weak self] _ in
            self?.showLogin()
            }, forEvents: .TouchUpInside, analyticsEvent: signInEvent)
        
        registerButton.setTitle(Strings.registerText, forState: .Normal)
        let signUpEvent = OEXAnalytics.registerEvent()
        registerButton.oex_addAction({ [weak self] _ in
            self?.showRegistration()
            }, forEvents: .TouchUpInside, analyticsEvent: signUpEvent)
        
        bottomBar.addSubview(registerButton)
        bottomBar.addSubview(signInButton)
        bottomBar.addSubview(line)
        
        signInButton.snp_makeConstraints { (make) in
            make.centerY.equalTo(bottomBar)
            make.top.equalTo(bottomBar)
            make.bottom.equalTo(bottomBar)
            make.trailing.equalTo(bottomBar)
            make.leading.equalTo(line.snp_trailing)
        }
        
        registerButton.snp_makeConstraints { (make) in
            make.centerY.equalTo(bottomBar)
            make.top.equalTo(bottomBar)
            make.bottom.equalTo(bottomBar)
            make.leading.equalTo(bottomBar)
            make.trailing.equalTo(line.snp_leading)        }
        
        line.backgroundColor = OEXStyles.sharedStyles().neutralBase()
        
        line.snp_makeConstraints { (make) in
            make.top.equalTo(bottomBar)
            make.bottom.equalTo(bottomBar)
            make.centerX.equalTo(bottomBar)
            make.width.equalTo(1)
        }
        
        addSubview(bottomBar)
        
        bottomBar.snp_makeConstraints { (make) in
            make.edges.equalTo(self)
        }
        
    }
    
    //MARK: - Actions
    func showLogin() {
        environment?.router?.showLoginScreenFromController(firstAvailableUIViewController(), completion: nil)
    }
    
    func showRegistration() {
        environment?.router?.showSignUpScreenFromController(firstAvailableUIViewController(), completion: nil)
    }
}
