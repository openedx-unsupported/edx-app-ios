//
//  EnrolledCoursesViewController.swift
//  edX
//
//  Created by Akiva Leffert on 12/21/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

var isActionTakenOnUpgradeSnackBar: Bool = false

class EnrolledCoursesViewController : OfflineSupportViewController, CoursesContainerViewControllerDelegate, PullRefreshControllerDelegate, LoadStateViewReloadSupport, InterfaceOrientationOverriding, BannerBrowserViewControllerDelegate {
    
    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & NetworkManagerProvider & ReachabilityProvider & OEXRouterProvider & OEXStylesProvider & OEXInterfaceProvider & RemoteConfigProvider
    
    private let environment : Environment
    private let coursesContainer : CoursesContainerViewController
    private let loadController = LoadStateViewController()
    private let refreshController = PullRefreshController()
    private let insetsController = ContentInsetsController()
    fileprivate let enrollmentFeed: Feed<[UserCourseEnrollment]?>
    private let userPreferencesFeed: Feed<UserPreference?>

    init(environment: Environment) {
        coursesContainer = CoursesContainerViewController(environment: environment, context: .enrollmentList)
        enrollmentFeed = environment.dataManager.enrollmentManager.feed
        userPreferencesFeed = environment.dataManager.userPreferenceManager.feed
        self.environment = environment
        
        super.init(env: environment)
        navigationItem.title = Strings.courses
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

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
        
        fetchBanner()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        showVersionUpgradeSnackBarIfNecessary()
        super.viewWillAppear(animated)

        hideSnackBarForFullScreenError()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        environment.analytics.trackScreen(withName: OEXAnalyticsScreenMyCourses)
        
        // show banner if needed
        // save banner shown to userdefaults
        //showWhatsNewIfNeeded()
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
    
    private var isCourseDiscoveryEnabled: Bool {
        return environment.config.discovery.course.isEnabled
    }
    
    private func setupListener() {
        enrollmentFeed.output.listen(self) {[weak self] result in
            if !(self?.enrollmentFeed.output.active ?? false) {
                self?.refreshController.endRefreshing()
            }
            
            switch result {
            case let Result.success(enrollments):
                if let enrollments = enrollments {
                    self?.coursesContainer.courses = enrollments.compactMap { $0.course }
                    self?.coursesContainer.collectionView.reloadData()
                    self?.loadController.state = .Loaded
                    if enrollments.count <= 0 {
                        self?.enrollmentsEmptyState()
                    }
                }
                else {
                    self?.loadController.state = .Initial
                }
            case let Result.failure(error):
                //App is showing occasionally error on app launch, so skipping first error on app launch
                //TODO: Find exact root cause of error and remove this patch
                // error code -100 is for unknown error
                if error.code == -100 {
                    return
                }
                
                self?.loadController.state = LoadState.failed(error: error)
                if error.errorIsThisType(NSError.oex_outdatedVersionError()) {
                    self?.hideSnackBar()
                }
            }
        }
    }
    
    private func fetchBanner() {
        let request = NetworkRequest<[String]>(
            method: .GET,
            path: "/notices/api/v1/unacknowledged",
            requiresAuth: true,
            deserializer: .jsonResponse({ response, json in
                if response.statusCode == OEXHTTPStatusCode.code200OK.rawValue {
                    let values = json["results"].arrayValue.map { $0.stringValue }
                    if !values.isEmpty {
                        return Success(v: values)
                    } else {
                        return Failure()
                    }
                    
                } else {
                    return Failure()
                }
        }))
        environment.networkManager.taskForRequest(request) { result in
            if let link = result.data?.first,
               let url = URL(string: link) {
                self.environment.router?.showBannerBrowserViewController(from: self, url: url, delegate: self)
            }
        }
    }
    
    private func acknowledge() {        
        let request = NetworkRequest<String>(
            method: .POST,
            path: "/notices/api/v1/acknowledge",
            requiresAuth: true,
            body: .jsonBody(JSON([
                "notice_id": "",
                "acknowledgment_type": "confirmed"
            ])),
            deserializer: .noContent({ response in
                if response.statusCode == OEXHTTPStatusCode.code200OK.rawValue {
                    print("success")
                    return Success(v: "success")
                } else {
                    print("failure")
                    return Failure()
                }
        }))
        environment.networkManager.taskForRequest(request) { result in
            print(result.data)
        }
    }
    
    private func deleteAccount() {
        
    }
    
    private func enrollmentsEmptyState() {
        if !isCourseDiscoveryEnabled {
            let error = NSError.oex_error(with: .unknown, message: Strings.EnrollmentList.noEnrollment)
            loadController.state = LoadState.failed(error: error, icon: Icon.UnknownError)
        }
    }
    
    private func setupObservers() {
        let config = environment.config
        NotificationCenter.default.oex_addObserver(observer: self, name: NSNotification.Name.OEXExternalRegistrationWithExistingAccount.rawValue) { (notification, observer, _) -> Void in
            let platform = config.platformName()
            let service = notification.object as? String ?? ""
            let message = Strings.externalRegistrationBecameLogin(platformName: platform, service: service)
            observer.showOverlay(withMessage: message)
        }
        
        NotificationCenter.default.oex_addObserver(observer: self, name: AppNewVersionAvailableNotification) { (notification, observer, _) -> Void in
            observer.showVersionUpgradeSnackBarIfNecessary()
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
        environment.router?.showValuePropDetailView(from: self, type: .courseEnrollment, course: course) { [weak self] in
            self?.environment.analytics.trackValuePropModal(with: .CourseEnrollment, courseId: course.course_id ?? "")
        }
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
    
    //MARK:- PullRefreshControllerDelegate method
    func refreshControllerActivated(controller: PullRefreshController) {
        enrollmentFeed.refresh()
        userPreferencesFeed.refresh()
    }
    
    //MARK:- LoadStateViewReloadSupport method 
    func loadStateViewReload() {
        refreshIfNecessary()
    }
    
    //MARK:- BannerBrowserViewControllerDelegate
    func didTapOnAcknowledge() {
        acknowledge()
    }
    
    func didTapOnDeleteAccount() {
        deleteAccount()
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
