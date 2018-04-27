//
//  LoginSplashViewController.swift
//  edX
//
//  Created by Zeeshan Arif on 4/26/18.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit

@objc class LoginSplashViewController: UIViewController {

    // MARK: UIProperties
    lazy var backgroundImageView: UIImageView = {
       let imageView = UIImageView()
        imageView.accessibilityIdentifier = "LoginSplashViewController:background-image-view"
        imageView.image = UIImage(named: "launchBackground")
        return imageView
    }()
    
    lazy var logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.accessibilityIdentifier = "LoginSplashViewController:logo-image-view"
        imageView.image = UIImage(named: "logo")
        return imageView
    }()
    
    lazy var signInButton: UIButton = {
        let button = UIButton()
        button.accessibilityIdentifier = "LoginSpashViewController:sign-in-button"
        let style = OEXMutableTextStyle(weight: .bold, size: .base, color: self.environment.styles.neutralWhite())
        button.setAttributedTitle(style.attributedString(withText: Strings.loginSplashSignIn), for: .normal)
        button.oex_addAction({ [weak self] _ in
            self?.environment.router?.showLoginScreen(from: self, completion: nil)
        }, for: .touchUpInside)
        return button
    }()
    
    lazy var signUpButton: UIButton = {
        let button = UIButton()
        button.accessibilityIdentifier = "LoginSpashViewController:sign-up-button"
        button.applyButtonStyle(style: self.environment.styles.filledPrimaryButtonStyle, withTitle: Strings.loginSplashSignUp)
        button.oex_addAction({ [weak self] _ in
            self?.environment.router?.showSignUpScreen(from: self, completion: nil)
        }, for: .touchUpInside)
        return button
    }()
    
    
    // MARK: Properties
    let environment: RouterEnvironment
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    // MARK: Initialisers
    init(environment: RouterEnvironment) {
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // MARK: ViewController Life Cycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        addSubViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setToolbarHidden(true, animated: animated)
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    private func addSubViews() {
        view.addSubview(backgroundImageView)
        view.addSubview(logoImageView)
        view.addSubview(signUpButton)
        view.addSubview(signInButton)
        configureConstraints()
    }
    
    private func configureConstraints() {
        backgroundImageView.snp_makeConstraints { make in
            make.edges.equalTo(view)
        }
        
        logoImageView.snp_makeConstraints { make in
            make.top.equalTo(view).offset(50)
            make.centerX.equalTo(view)
        }
        
        signUpButton.snp_makeConstraints { make in
            make.bottom.equalTo(signInButton.snp_top).offset(-StandardHorizontalMargin)
            make.centerX.equalTo(view)
            make.width.equalTo(signInButton)
        }
        
        signInButton.snp_makeConstraints { make in
            make.bottom.equalTo(view).inset(40)
            make.centerX.equalTo(view)
        }
        
    }
}
