//
//  EnrolledTabBarViewController.swift
//  edX
//
//  Created by Salman on 19/12/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

private enum TabBarOptions: Int {
    case MyCourse, CourseCatalog, Debug
    static let allValues = [MyCourse, CourseCatalog, Debug]
}

class EnrolledTabBarViewController: UITabBarController, UITabBarControllerDelegate {

    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & NetworkManagerProvider & OEXRouterProvider & OEXInterfaceProvider & ReachabilityProvider & OEXSessionProvider & OEXStylesProvider
    
    private let environment: Environment
    fileprivate var tabBarItems : [CourseDashboardTabBarItem] = []
    fileprivate var additionalTabBarItems : [CourseDashboardTabBarItem] = []
    var userProfilePicture = ProfileImageView()
    private let UserProfileImageSize = CGSize(width: 30, height: 30)
    
    var profileFeed: Feed<UserProfile>?
    
    init(environment: Environment) {
        self.environment = environment
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setScreenTitle()
        addAccountButton()
        addProfileButton()
        setupProfileLoader()
        updateUIWithUserInfo()
        prepareTabViewData()
        delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func courseCatalogTitle() -> String {
        switch environment.config.courseEnrollmentConfig.type {
        case .Native:
            return Strings.findCourses
        default:
            return Strings.discover
        }
    }
    
    private func setScreenTitle() {
        let option = TabBarOptions.allValues[0]
        switch option {
        case .CourseCatalog:
            navigationItem.title = courseCatalogTitle()
        default:
            navigationItem.title = Strings.courses
        }
    }
    
    private func prepareTabViewData() {
        tabBarItems = []
        var item : CourseDashboardTabBarItem
        for option in TabBarOptions.allValues {
            switch option {
            case .MyCourse:
                item = CourseDashboardTabBarItem(title: Strings.courses, viewController: EnrolledCoursesViewController(environment: self.environment), icon: Icon.Courseware, detailText: Strings.Dashboard.courseCourseDetail)
                tabBarItems.append(item)
            case .CourseCatalog:
                guard environment.config.courseEnrollmentConfig.isCourseDiscoveryEnabled() else { break }
                item = CourseDashboardTabBarItem(title: courseCatalogTitle(), viewController: getDiscoveryViewController(), icon: Icon.Search, detailText: Strings.Dashboard.courseCourseDetail)
                tabBarItems.append(item)
            case .Debug:
                if environment.config.shouldShowDebug() {
                    item = CourseDashboardTabBarItem(title:Strings.debug, viewController: DebugMenuViewController(environment: environment), icon: Icon.Search, detailText: Strings.Dashboard.courseCourseDetail)
                    additionalTabBarItems.append(item)
                }
            }
        }
        
        if additionalTabBarItems.count > 0 {
            let item = CourseDashboardTabBarItem(title:Strings.resourses, viewController: EnrolledTabBarAdditionalViewController(environment: environment, cellItems: additionalTabBarItems), icon: Icon.MoreOptionsIcon, detailText:"")
            tabBarItems.append(item)
        }
    
        loadTabBarViewControllers(tabBarItems: tabBarItems)
    }

    func getDiscoveryViewController() -> UIViewController {
        let controller: UIViewController
        switch environment.config.courseEnrollmentConfig.type {
        case .Webview:
            controller = OEXFindCoursesViewController(bottomBar: nil)
        case .Native, .None:
            controller = CourseCatalogViewController(environment: environment)
        }
        
        return controller
    }
    
    private func loadTabBarViewControllers(tabBarItems: [CourseDashboardTabBarItem]) {
        var controllers :[UIViewController] = []
        for tabBarItem in tabBarItems {
            let controller = tabBarItem.viewController
            controller.tabBarItem = UITabBarItem(title:tabBarItem.title, image:tabBarItem.icon.imageWithFontSize(size: 20), selectedImage: tabBarItem.icon.imageWithFontSize(size: 20))
            controllers.append(controller)
        }
        viewControllers = controllers
        tabBar.isHidden = (tabBarItems.count == 1)
    }
    
    private func setupProfileLoader() {
        guard environment.config.profilesEnabled else { return }
        profileFeed = environment.dataManager.userProfileManager.feedForCurrentUser()
        
        profileFeed?.output.listen(self,  success: { profile in
            self.userProfilePicture.remoteImage = profile.image(networkManager: self.environment.networkManager)
        }, failure : { _ in
            Logger.logError("Profiles", "Unable to fetch profile")
        })
    }

    private func addProfileButton() {
        if environment.config.profilesEnabled {
            let profileView = UIView(frame: CGRect(x: 0, y: 0, width: UserProfileImageSize.width, height: UserProfileImageSize.height))
            let profileButton = UIButton()
            profileView.addSubview(userProfilePicture)
            profileView.addSubview(profileButton)
    
            profileButton.snp_makeConstraints { (make) in
                make.edges.equalTo(profileView)
            }
            
            userProfilePicture.snp_makeConstraints { (make) in
                make.edges.equalTo(profileView)
            }
            
            profileButton.oex_addAction({[weak self] _  in
                guard let currentUserName = self?.environment.session.currentUser?.username else { return }
                self?.environment.router?.showProfileForUsername(controller: self, username: currentUserName, modalTransitionStylePresent: true)
            }, for: .touchUpInside)
            
            navigationItem.leftBarButtonItem = UIBarButtonItem(customView: profileView)
        }
    }
    
    private func addAccountButton() {
        let accountButton = UIBarButtonItem(image: Icon.AccountIcon.imageWithFontSize(size: 20.0), style: .plain, target: nil, action: nil)
        accountButton.accessibilityLabel = Strings.userAccount
        navigationItem.rightBarButtonItem = accountButton
        
        accountButton.oex_setAction { [weak self] in
            self?.environment.router?.showAccount(controller: self, modalTransitionStylePresent: true)
        }
    }
    
    private func updateUIWithUserInfo() {
        profileFeed?.refresh()
    }
}

extension EnrolledTabBarViewController {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController){
        navigationItem.title = viewController.navigationItem.title
    }
}
