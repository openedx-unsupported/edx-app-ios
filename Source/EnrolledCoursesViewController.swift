//
//  EnrolledCoursesViewController.swift
//  edX
//
//  Created by Akiva Leffert on 12/21/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

var isActionTakenOnUpgradeSnackBar: Bool = false

class EnrolledCoursesViewController : OfflineSupportViewController, CoursesContainerViewControllerDelegate, InterfaceOrientationOverriding {
    
    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & NetworkManagerProvider & ReachabilityProvider & OEXRouterProvider & OEXStylesProvider & OEXInterfaceProvider & ServerConfigProvider & OEXSessionProvider
    
    let environment : Environment
    private let coursesContainer : CoursesContainerViewController
    private let loadController = LoadStateViewController()
    private let refreshController = PullRefreshController()
    private let insetsController = ContentInsetsController()
    fileprivate let enrollmentFeed: Feed<[UserCourseEnrollment]?>
    private let userPreferencesFeed: Feed<UserPreference?>
    var handleBannerOnStart: Bool = false // this will be used to send first call for the banners
    lazy var courseUpgradeHelper = CourseUpgradeHelper.shared
    
    init(environment: Environment) {
        coursesContainer = CoursesContainerViewController(environment: environment, context: .enrollmentList)
        enrollmentFeed = environment.dataManager.enrollmentManager.feed
        userPreferencesFeed = environment.dataManager.userPreferenceManager.feed
        self.environment = environment
        
        super.init(env: environment)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = Strings.courses
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        view.accessibilityIdentifier = "enrolled-courses-screen"
        view.backgroundColor = environment.styles.standardBackgroundColor()
        
        addChild(coursesContainer)
        coursesContainer.didMove(toParent: self)
        loadController.setupInController(controller: self, contentView: coursesContainer.view)
        
        view.addSubview(coursesContainer.view)
        coursesContainer.view.snp.makeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
        coursesContainer.delegate = self
        
        refreshController.setupInScrollView(scrollView: coursesContainer.collectionView)
        refreshController.delegate = self
        
        insetsController.setupInController(owner: self, scrollView: coursesContainer.collectionView)
        insetsController.addSource(source: refreshController)
        
        // We visually separate each course card so we also need a little padding
        // at the bottom to match
        insetsController.addSource(
            source: ConstantInsetsSource(insets: UIEdgeInsets(top: 0, left: 0, bottom: StandardVerticalMargin, right: 0), affectsScrollIndicators: false)
        )
        
        enrollmentFeed.refresh()
        userPreferencesFeed.refresh()
        
        setupListener()
        setupObservers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        showVersionUpgradeSnackBarIfNecessary()
        super.viewWillAppear(animated)
        
        hideSnackBarForFullScreenError()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        environment.analytics.trackScreen(withName: OEXAnalyticsScreenMyCourses)
        showWhatsNewIfNeeded()
        
        if !handleBannerOnStart {
            handleBannerOnStart = true
            handleBanner()
        }
        
    }
    
    override func reloadViewData() {
        refreshIfNecessary()
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
    
    private var isDiscoveryEnabled: Bool {
        return environment.config.discovery.isEnabled
    }
    
    private func handleUpgradationLoader(success: Bool) {
        guard let model = courseUpgradeHelper.courseUpgradeModel else { return }
        
        if model.screen == .myCourses {
            // show alert with retry option to reload the enrollments
            if success == false {
                courseUpgradeHelper.removeLoader(success: success) { [weak self] in
                    self?.environment.dataManager.enrollmentManager.forceReload()
                }
            }
            else {
                courseUpgradeHelper.removeLoader(success: success, removeView: true)
            }
        }
        else {
            navigateToScreenAterCourseUpgrade()
        }
    }
    
    private func setupListener() {
        enrollmentFeed.output.listen(self) {[weak self] result in
            if !(self?.enrollmentFeed.output.active ?? false) {
                self?.refreshController.endRefreshing()
            }
                        
            switch result {
            case let .success(enrollments):
                if let enrollments = enrollments {
                    self?.coursesContainer.courses = enrollments.compactMap { $0.course }
                    self?.coursesContainer.collectionView.reloadData()
                    self?.loadController.state = .Loaded
                    self?.handleUpgradationLoader(success: true)
                }
                else {
                    self?.loadController.state = .Initial
                    self?.handleUpgradationLoader(success: false)
                }
            case let .failure(error):
                //App is showing occasionally error on app launch, so skipping first error on app launch
                //TODO: Find exact root cause of error and remove this patch
                // error code -100 is for unknown error
                if error.code == -100 {
                    return
                }
                
                self?.loadController.state = .Loaded
                //self?.showError()
                if error.errorIsThisType(NSError.oex_outdatedVersionError()) {
                    //self?.hideSnackBar()
                }
                
                self?.handleUpgradationLoader(success: false)
            }
        }
    }
    
    private func enrollmentsEmptyState() {
        if !isDiscoveryEnabled {
            let error = NSError.oex_error(with: .unknown, message: Strings.Dashboard.generalErrorMessage)
            loadController.state = LoadState.failed(error: error, icon: Icon.UnknownError)
        }
    }
    
    private func showError() {
        loadController.state = .Loaded
        coursesContainer.showError()
    }
    
    private func setupObservers() {
        let config = environment.config
        NotificationCenter.default.oex_addObserver(observer: self, name: NSNotification.Name.OEXExternalRegistrationWithExistingAccount.rawValue) { (notification, observer, _) -> Void in
            let platform = config.platformName()
            let service = notification.object as? String ?? ""
            let message = Strings.externalRegistrationBecameLogin(platformName: platform, service: service)
            observer.showOverlay(withMessage: message)
        }
        
        NotificationCenter.default.oex_addObserver(observer: self, name: AppNewVersionAvailableNotification) { (_, observer, _) -> Void in
            observer.showVersionUpgradeSnackBarIfNecessary()
        }
        
        NotificationCenter.default.oex_addObserver(observer: self, name: UIApplication.didBecomeActiveNotification.rawValue) { _, observer, _ in
            observer.handleBanner()
        }
        
        NotificationCenter.default.oex_addObserver(observer: self, name: CourseUpgradeCompletionNotification) { _, observer, _ in
            observer.handleCourseUpgrade()
        }

        NotificationCenter.default.oex_addObserver(observer: self, name: UnfullfilledTransctionsNotification) { _, observer, _ in
            observer.resolveUnfinishedPaymentIfRequired()
        }
    }
    
    func refreshIfNecessary() {
        if environment.reachability.isReachable() && !enrollmentFeed.output.active {
            enrollmentFeed.refresh()
            if loadController.state.isError {
                loadController.state = .Initial
            }
        }
    }
    
    private func showVersionUpgradeSnackBarIfNecessary() {
        showVersionUpgradeSnackBar(string: "testing")
        return
        if let _ = VersionUpgradeInfoController.sharedController.latestVersion {
            var infoString = Strings.VersionUpgrade.newVersionAvailable
            if let _ = VersionUpgradeInfoController.sharedController.lastSupportedDateString {
                infoString = Strings.VersionUpgrade.deprecatedMessage
            }
            
            if !isActionTakenOnUpgradeSnackBar {
                showVersionUpgradeSnackBar(string: infoString)
            }
        }
        else {
            hideSnackBar()
        }
    }
    
    private func hideSnackBarForFullScreenError() {
        if coursesContainer.courses.count <= 0 {
            hideSnackBar()
        }
    }
    
    func coursesContainerChoseCourse(course: OEXCourse) {
        if let course_id = course.course_id {
            environment.router?.showCourseWithID(courseID: course_id, fromController: self, animated: true)
        }
        else {
            preconditionFailure("course without a course id")
        }
    }
    
    func showValuePropDetailView(with course: OEXCourse) {
        environment.analytics.trackValuePropLearnMore(courseID: course.course_id ?? "", screenName: AnalyticsScreenName.CourseEnrollment)
        environment.router?.showValuePropDetailView(from: self, screen: .myCourses, course: course) { [weak self] in
            self?.environment.analytics.trackValuePropModal(with: .CourseEnrollment, courseId: course.course_id ?? "")
        }
    }
    
    func reload() {
        loadController.state = .Initial
        refreshIfNecessary()
    }
    
    private func showWhatsNewIfNeeded() {
        if WhatsNewViewController.canShowWhatsNew(environment: environment as? RouterEnvironment) {
            environment.router?.showWhatsNew(fromController: self)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        coursesContainer.collectionView.collectionViewLayout.invalidateLayout()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

//MARK:- PullRefreshControllerDelegate method
extension EnrolledCoursesViewController: PullRefreshControllerDelegate {
    func refreshControllerActivated(controller: PullRefreshController) {
        enrollmentFeed.refresh()
        userPreferencesFeed.refresh()
    }
}

//MARK:- LoadStateViewReloadSupport method
extension EnrolledCoursesViewController: LoadStateViewReloadSupport {
    func loadStateViewReload() {
        refreshIfNecessary()
    }
}

// For testing use only
extension EnrolledCoursesViewController {
    var t_loaded: OEXStream<()> {
        return self.enrollmentFeed.output.map {_ in
            return ()
        }
    }
}
