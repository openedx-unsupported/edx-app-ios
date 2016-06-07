//
//  StartupViewController.swift
//  edX
//
//  Created by Michael Katz on 5/16/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

class StartupViewController: UIViewController {

    typealias Environment = protocol<OEXRouterProvider>


    private let backgroundImageView = UIImageView()
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

    // MARK: - View Setup

    private func setupBackground() {
        let backgroundImage = UIImage(named: "splash-start-lg")
        backgroundImageView.image = backgroundImage
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

        view.addSubview(logoImageView)

        logoImageView.snp_makeConstraints { (make) in
            make.centerY.equalTo(view.snp_bottom).dividedBy(5.0)
            make.centerX.equalTo(view.snp_centerX)
        }
    }

    private func setupDiscoverButtons() {

        let discoverButton = UIButton()
        discoverButton.applyButtonStyle(OEXStyles.sharedStyles().filledPrimaryButtonStyle, withTitle: Strings.Startup.discovercourses)
        discoverButton.oex_addAction({ [weak self] _ in
            self?.showCourses()
            }, forEvents: .TouchUpInside)

        view.addSubview(discoverButton)


        let exploreButton = UIButton()
        exploreButton.applyButtonStyle(OEXStyles.sharedStyles().filledPrimaryButtonStyle, withTitle: Strings.Startup.exploresubjects)
        exploreButton.oex_addAction({ [weak self] _ in
            self?.exploreSubjects()
            }, forEvents: .TouchUpInside)

        view.addSubview(exploreButton)

        discoverButton.snp_makeConstraints { (make) in
            make.centerY.equalTo(view.snp_centerY).inset(-35)
            make.leading.equalTo(view.snp_leading).offset(30)
            make.trailing.equalTo(view.snp_trailing).inset(30)
        }

        exploreButton.snp_makeConstraints { (make) in
            make.centerY.equalTo(view.snp_centerY).inset(35)
            make.leading.equalTo(view.snp_leading).offset(30)
            make.trailing.equalTo(view.snp_trailing).inset(30)
        }
    }

    private func setupBottomBar() {
        let bottomBar = makeBottomBar(false)
        view.addSubview(bottomBar)
        bottomBar.snp_makeConstraints { (make) in
            make.height.equalTo(70)
            make.bottom.equalTo(view)
            make.leading.equalTo(view.snp_leading)
            make.trailing.equalTo(view.snp_trailing)
        }

    }

    private func makeBottomBar(dismissFirst: Bool) -> UIView {
        let bottomBar = UIView()
        bottomBar.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.90)

        let signInButton = UIButton()
        signInButton.setTitle(Strings.signInButtonText, forState: .Normal)
        signInButton.oex_addAction({ [weak self] _ in
            if dismissFirst {
                self?.dismissViewControllerAnimated(false, completion: {
                    self?.showLogin()
                })
            } else {
                self?.showLogin()
            }
            }, forEvents: .TouchUpInside)

        let signUpButton = UIButton()
        signUpButton.setTitle(Strings.signUpButtonText, forState: .Normal)
        signUpButton.oex_addAction({ [weak self] _ in
            if dismissFirst {
                self?.dismissViewControllerAnimated(false, completion: {
                    self?.showRegistration()
                })
            } else {
                self?.showRegistration()
            }
            }, forEvents: .TouchUpInside)


        bottomBar.addSubview(signUpButton)
        bottomBar.addSubview(signInButton)

        signInButton.snp_makeConstraints { (make) in
            make.centerY.equalTo(bottomBar)
            make.centerX.equalTo(bottomBar.snp_trailing).multipliedBy(0.75)
        }

        signUpButton.snp_makeConstraints { (make) in
            make.centerY.equalTo(bottomBar)
            make.centerX.equalTo(bottomBar.snp_trailing).multipliedBy(0.25)
        }

        let line = UIView()
        line.backgroundColor = OEXStyles.sharedStyles().neutralBase()
        bottomBar.addSubview(line)
        line.snp_makeConstraints { (make) in
            make.top.equalTo(bottomBar)
            make.bottom.equalTo(bottomBar)
            make.centerX.equalTo(bottomBar)
            make.width.equalTo(1)
        }

        return bottomBar
    }

    //MARK: - Actions
    func showLogin() {
        self.environment.router?.showLoginScreenFromController(self, completion: nil)
    }

    func showRegistration() {
        self.environment.router?.showSignUpScreenFromController(self, completion: nil)
    }

    func showCourses() {
        let bottomBar = makeBottomBar(true)
        self.environment.router?.showCourseCatalog(bottomBar)
    }

    func exploreSubjects() {
        let bottomBar = makeBottomBar(true)
        self.environment.router?.showExploreCourses(bottomBar)
    }
}
