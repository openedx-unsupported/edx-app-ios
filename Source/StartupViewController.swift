//
//  StartupViewController.swift
//  edX
//
//  Created by Michael Katz on 5/16/16.
//  Copyright © 2016 edX. All rights reserved.
//

import Foundation

var transparentDiscoverButtonStyle: ButtonStyle {
    let buttonMargins : CGFloat = 8
    let borderStyle = BorderStyle(cornerRadius: .Size(10), width: .Size(3), color: OEXStyles.sharedStyles().discoveryButtonColor())
    let textStyle = OEXTextStyleWithShadow(weight: .Light, size: .XXXLarge, color: OEXStyles.sharedStyles().neutralWhite())
    let textShadowStyle = ShadowStyle(angle: 90, color: UIColor.blackColor(), opacity: 0.35, distance: 1, size: 1)
    textStyle.shadow = textShadowStyle
    let shadowStyle = ShadowStyle(angle: 90, color: UIColor.blackColor(), opacity: 0.45, distance: 2, size: 2)
    return ButtonStyle(textStyle: textStyle, backgroundColor: OEXStyles.sharedStyles().discoveryButtonColor().colorWithAlphaComponent(0.78), borderStyle: borderStyle, contentInsets : UIEdgeInsetsMake(buttonMargins, buttonMargins, buttonMargins, buttonMargins), shadow: shadowStyle)
}

class StartupViewController: UIViewController {

    typealias Environment = protocol<OEXRouterProvider>


    private let backgroundImageView = UIImageView()
    private let logoImageView = UIImageView()
    private let discoverButton = UIButton()
    private let bottomButtons = TZStackView()

    private let pagerScrollView = UIScrollView()
    private let pageIndicator = UIPageControl()
    private let valueProps = ["One","Two","Three","Four"]

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
        setupDiscoverButton()
        setupBottomButtons()
        setupPager()
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

    private func setupDiscoverButton() {
        discoverButton.applyButtonStyle(transparentDiscoverButtonStyle, withTitle: "DISCOVER COURSES")
        discoverButton.oex_addAction({ [weak self] _ in
            self?.showCourses()
            }, forEvents: .TouchUpInside)

        view.addSubview(discoverButton)

        discoverButton.snp_makeConstraints { (make) in
            make.centerY.equalTo(view.snp_centerY)
            make.leading.equalTo(view.snp_leading).offset(30)
            make.trailing.equalTo(view.snp_trailing).inset(30)
            make.height.equalTo(60)
        }
    }

    private func setupBottomButtons() {
        bottomButtons.distribution = TZStackViewDistribution.FillEqually
        bottomButtons.axis = .Horizontal
        bottomButtons.spacing = 40

        let signInButton = UIButton()
        signInButton.applyButtonStyle(OEXStyles.sharedStyles().filledButtonStyle(OEXStyles.sharedStyles().primaryBaseColor()), withTitle: "Sign in")
        signInButton.oex_addAction({ [weak self] _ in
            self?.showLogin()
            }, forEvents: .TouchUpInside)

        let signUpButton = UIButton()
        signUpButton.applyButtonStyle(OEXStyles.sharedStyles().filledButtonStyle(OEXStyles.sharedStyles().secondaryBaseColor()), withTitle: "Sign up")
        signUpButton.oex_addAction({ [weak self] _ in
            self?.showRegistration()
            }, forEvents: .TouchUpInside)


        bottomButtons.addArrangedSubview(signUpButton)
        bottomButtons.addArrangedSubview(signInButton)

        view.addSubview(bottomButtons)
        bottomButtons.snp_makeConstraints { (make) in
            make.bottom.equalTo(view).inset(15)
            make.leading.equalTo(view.snp_leading).offset(30)
            make.trailing.equalTo(view.snp_trailing).inset(30)
        }
    }

    private func setupPager() {

        pagerScrollView.backgroundColor = UIColor.blueColor().colorWithAlphaComponent(0.6)
        pagerScrollView.pagingEnabled = true
        pagerScrollView.scrollEnabled = true
        pagerScrollView.showsHorizontalScrollIndicator = false
        pagerScrollView.delegate = self
        view.addSubview(pagerScrollView)

        var lastLabel: UILabel?
        for phrase in valueProps {
            let label = UILabel()
            label.text = phrase
            label.textAlignment = .Center
            label.backgroundColor = UIColor.whiteColor().colorWithAlphaComponent(0.5)

            pagerScrollView.addSubview(label)
            label.snp_makeConstraints(closure: { (make) in
                make.width.equalTo(pagerScrollView)
                make.centerY.equalTo(pagerScrollView)
                make.leading.equalTo(lastLabel == nil ? pagerScrollView.snp_leading : lastLabel!.snp_trailing)
            })
            lastLabel = label
        }
        lastLabel?.snp_updateConstraints(closure: { (make) in
            make.trailing.equalTo(pagerScrollView)
        })


        pageIndicator.numberOfPages = valueProps.count
        pageIndicator.currentPage = 0
        pagerScrollView.addSubview(pageIndicator)
        pageIndicator.snp_makeConstraints { (make) in
            make.centerX.equalTo(pagerScrollView)
            make.bottom.equalTo(pagerScrollView).inset(10)
        }


        pagerScrollView.snp_makeConstraints { (make) in
            make.top.equalTo(discoverButton.snp_bottom)
            make.bottom.equalTo(bottomButtons.snp_top)
            make.leading.equalTo(view.snp_leading)
            make.trailing.equalTo(view.snp_trailing)
        }


    }

    //MARK: - Actions
    func showLogin() {
        self.environment.router?.showLoginScreenFromController(self, completion: nil)

    }

    func showRegistration() {
        self.environment.router?.showSignUpScreenFromController(self)
    }

    func showCourses() {
        self.environment.router?.showCourseCatalog()
    }
}

extension StartupViewController : UIScrollViewDelegate {
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let currentPage = floor(scrollView.contentOffset.x / scrollView.contentSize.width)
        pageIndicator.currentPage = Int(currentPage)
    }
}
