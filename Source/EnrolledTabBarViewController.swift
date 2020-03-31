//
//  EnrolledTabBarViewController.swift
//  edX
//
//  Created by Salman on 19/12/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

private enum TabBarOptions: Int {
    case Course, Program, CourseCatalog, Debug
    static let options = [Course, Program, CourseCatalog, Debug]
    
    func title(config: OEXConfig? = nil) -> String {
        switch self {
        case .Course:
            return Strings.courses
        case .Program:
            return Strings.programs
        case .CourseCatalog:
            return config?.discovery.course.type == .native ? Strings.findCourses : Strings.discover
        case .Debug:
            return Strings.debug
        }
    }
}

class EnrolledTabBarViewController: UITabBarController, UITabBarControllerDelegate, InterfaceOrientationOverriding, ChromeCastConnectedButtonDelegate {
    
    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & NetworkManagerProvider & OEXRouterProvider & OEXInterfaceProvider & ReachabilityProvider & OEXSessionProvider & OEXStylesProvider
    
    fileprivate let environment: Environment
    private var tabBarItems : [TabBarItem] = []
    
    // add the additional resources options like 'debug'(special developer option) in additionalTabBarItems
    private var additionalTabBarItems : [TabBarItem] = []
    
    private var userProfileImageView = ProfileImageView()
    private let UserProfileImageSize = CGSize(width: 30, height: 30)
    private var profileFeed: Feed<UserProfile>?
    private let tabBarImageFontSize : CGFloat = 20
    static var courseCatalogIndex: Int = 0
    
    private var screenTitle: String {
        guard let option = TabBarOptions.options.first else {return Strings.courses}
        return option.title(config: environment.config)
    }
    
    init(environment: Environment) {
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = screenTitle
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        addAccountButton()
        addProfileButton()
        setupProfileLoader()
        prepareTabViewData()
        delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    private func prepareTabViewData() {
        tabBarItems = []
        var item : TabBarItem
        for option in TabBarOptions.options {
            switch option {
            case .Course:
                item = TabBarItem(title: option.title(), viewController: EnrolledCoursesViewController(environment: environment), icon: Icon.Courseware, detailText: Strings.Dashboard.courseCourseDetail)
                tabBarItems.append(item)
            case .Program:
                guard environment.config.programConfig.enabled, let programsURL = environment.config.programConfig.programURL else { break }
                item = TabBarItem(title: option.title(), viewController: ProgramsViewController(environment: environment, programsURL: programsURL), icon: Icon.Clone, detailText: Strings.Dashboard.courseCourseDetail)
                tabBarItems.append(item)
            case .CourseCatalog:
                guard let router = environment.router,
                    let discoveryController = router.discoveryViewController() else { break }
                item = TabBarItem(title: option.title(config: environment.config), viewController: discoveryController, icon: Icon.Discovery, detailText: Strings.Dashboard.courseCourseDetail)
                tabBarItems.append(item)
                EnrolledTabBarViewController.courseCatalogIndex = tabBarItems.count - 1
            case .Debug:
                if environment.config.shouldShowDebug() {
                    item = TabBarItem(title: option.title(), viewController: DebugMenuViewController(environment: environment), icon: Icon.Discovery, detailText: Strings.Dashboard.courseCourseDetail)
                    additionalTabBarItems.append(item)
                }
            }
        }
        
        if additionalTabBarItems.count > 0 {
            let item = TabBarItem(title:Strings.resourses, viewController:
                AdditionalTabBarViewController(environment: environment, cellItems: additionalTabBarItems), icon: Icon.MoreOptionsIcon, detailText: "")
            tabBarItems.append(item)
        }
    
        loadTabBarViewControllers(tabBarItems: tabBarItems)
    }
    
    private func loadTabBarViewControllers(tabBarItems: [TabBarItem]) {
        var controllers :[UIViewController] = []
        for tabBarItem in tabBarItems {
            let controller = tabBarItem.viewController
            controller.tabBarItem = UITabBarItem(title:tabBarItem.title, image:tabBarItem.icon.imageWithFontSize(size: tabBarImageFontSize), selectedImage: tabBarItem.icon.imageWithFontSize(size: tabBarImageFontSize))
            controller.tabBarItem.accessibilityIdentifier = "EnrolledTabBarViewController:tab-bar-item"
            controllers.append(controller)
        }
        viewControllers = controllers
        tabBar.isHidden = (tabBarItems.count == 1)
    }
    
    private func setupProfileLoader() {
        guard environment.config.profilesEnabled else { return }
        profileFeed = environment.dataManager.userProfileManager.feedForCurrentUser()
        
        profileFeed?.output.listen(self,  success: {[weak self] profile in
            if let weakSelf = self {
                weakSelf.userProfileImageView.remoteImage = profile.image(networkManager: weakSelf.environment.networkManager)
            }
        }, failure : { _ in
            Logger.logError("Profiles", "Unable to fetch profile")
        })
        profileFeed?.refresh()
    }

    private func addProfileButton() {
        if environment.config.profilesEnabled {
            let profileView = UIView(frame: CGRect(x: 0, y: 0, width: UserProfileImageSize.width, height: UserProfileImageSize.height))
            let profileButton = UIButton()
            profileButton.accessibilityHint = Strings.accessibilityShowUserProfileHint
            profileButton.accessibilityLabel = Strings.Accessibility.profileLabel
            profileView.addSubview(userProfileImageView)
            profileView.addSubview(profileButton)
            
            profileButton.snp.makeConstraints { make in
                make.edges.equalTo(profileView)
                make.width.equalTo(UserProfileImageSize.width)
                make.height.equalTo(UserProfileImageSize.height)
            }
            
            userProfileImageView.snp.makeConstraints { make in
                make.edges.equalTo(profileView)
                make.width.equalTo(UserProfileImageSize.width)
                make.height.equalTo(UserProfileImageSize.height)
            }
            
            profileButton.oex_addAction({[weak self] _  in
                guard let currentUserName = self?.environment.session.currentUser?.username else { return }
                self?.environment.router?.showProfileForUsername(controller: self, username: currentUserName, modal: true)
            }, for: .touchUpInside)
            
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: profileView)
        }
    }
    
    private func addAccountButton() {
        let accountButton = UIBarButtonItem(image: Icon.Account.imageWithFontSize(size: tabBarImageFontSize), style: .plain, target: nil, action: nil)
        accountButton.accessibilityLabel = Strings.userAccount
        accountButton.accessibilityIdentifier = "EnrolledTabBarViewController:account-button"
        navigationItem.rightBarButtonItem = accountButton

        accountButton.oex_setAction { [weak self] in
            self?.environment.router?.showAccount(controller: self, modalTransitionStylePresent: true)
        }
    }
    
    // MARK: Deep Linking
    @discardableResult
    func switchTab(with type: DeepLinkType) -> UIViewController {
        switch type {
        case .program, .programDetail:
            selectedIndex = tabBarViewControllerIndex(with: ProgramsViewController.self)
            break
        case .courseDiscovery, .courseDetail, .programDiscovery, .programDiscoveryDetail, .degreeDiscovery, .degreeDiscoveryDetail:
            let isCourseDiscoveryEnabled = environment.config.discovery.course.isEnabled
            let isProgramDiscoveryEnabled = environment.config.discovery.program.isEnabled
            let isDegreeDiscoveryEnabled = environment.config.discovery.degree.isEnabled
            
            if (isCourseDiscoveryEnabled && (isProgramDiscoveryEnabled || isDegreeDiscoveryEnabled)) {
                selectedIndex = tabBarViewControllerIndex(with: DiscoveryViewController.self)
            }
            else if isCourseDiscoveryEnabled {
                selectedIndex = environment.config.discovery.course.type == .webview ? tabBarViewControllerIndex(with: OEXFindCoursesViewController.self) : tabBarViewControllerIndex(with: CourseCatalogViewController.self)
            }
            break
        default:
            selectedIndex = 0
            break
        }
        navigationItem.title = titleOfViewController(index: selectedIndex)
        
        return tabBarItems[selectedIndex].viewController
    }
}

extension EnrolledTabBarViewController {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController){
        navigationItem.title = viewController.navigationItem.title
        if TabBarOptions.options[tabBarController.selectedIndex] == .CourseCatalog {
            environment.analytics.trackUserFindsCourses()
        }
    }
}
