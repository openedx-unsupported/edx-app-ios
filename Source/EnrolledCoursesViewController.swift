//
//  EnrolledCoursesViewController.swift
//  edX
//
//  Created by Akiva Leffert on 12/21/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

var isActionTakenOnUpgradeSnackBar: Bool = false

class EnrolledCoursesViewController : OfflineSupportViewController, CoursesCollectionViewControllerDelegate, PullRefreshControllerDelegate, LoadStateViewReloadSupport,InterfaceOrientationOverriding {
    
    typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & NetworkManagerProvider & ReachabilityProvider & OEXRouterProvider & OEXStylesProvider
    
    private let environment : Environment
    private let collectionController : CoursesCollectionViewController
    private let loadController = LoadStateViewController()
    private let refreshController = PullRefreshController()
    private let insetsController = ContentInsetsController()
    fileprivate let enrollmentFeed: Feed<[UserCourseEnrollment]?>
    private let userPreferencesFeed: Feed<UserPreference?>

    init(environment: Environment) {
        collectionController = CoursesCollectionViewController(environment: environment, context: .EnrollmentList)
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

        addChild(collectionController)
        collectionController.didMove(toParent: self)
        loadController.setupInController(controller: self, contentView: collectionController.view)
        
        view.addSubview(collectionController.view)
        collectionController.view.snp.makeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
        collectionController.delegate = self
        
        refreshController.setupInScrollView(scrollView: collectionController.collectionView)
        refreshController.delegate = self
        
        insetsController.setupInController(owner: self, scrollView: collectionController.collectionView)
        insetsController.addSource(source: refreshController)

        // We visually separate each course card so we also need a little padding
        // at the bottom to match
        insetsController.addSource(
            source: ConstantInsetsSource(insets: UIEdgeInsets(top: 0, left: 0, bottom: StandardVerticalMargin, right: 0), affectsScrollIndicators: false)
        )
        
        enrollmentFeed.refresh()
        userPreferencesFeed.refresh()
        
        setupListener()
        setupFooter()
        setupObservers()
        addFindCoursesButton()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        environment.analytics.trackScreen(withName: OEXAnalyticsScreenMyCourses)
        showVersionUpgradeSnackBarIfNecessary()
        super.viewWillAppear(animated)
        hideSnackBarForFullScreenError()
        showWhatsNewIfNeeded()
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

    private func addFindCoursesButton() {
        if environment.config.discovery.course.isEnabled {
            let findcoursesButton = UIBarButtonItem(barButtonSystemItem: .search, target: nil, action: nil)
            findcoursesButton.accessibilityLabel = Strings.findCourses
            navigationItem.rightBarButtonItem = findcoursesButton
            
            findcoursesButton.oex_setAction { [weak self] in
                self?.environment.router?.showCourseCatalog(fromController: self, bottomBar: nil)
            }
        }
    }
    
    private func setupListener() {
        enrollmentFeed.output.listen(self) {[weak self] result in
            if !(self?.enrollmentFeed.output.active ?? false) {
                self?.refreshController.endRefreshing()
            }
            
            switch result {
            case let Result.success(enrollments):
                if let enrollments = enrollments {
                    self?.collectionController.courses = enrollments.compactMap { $0.course }
                    self?.collectionController.collectionView.reloadData()
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
    
    private func setupFooter() {
        if isCourseDiscoveryEnabled {
            let footer = EnrolledCoursesFooterView()
            footer.findCoursesAction = {[weak self] in
                self?.environment.router?.showCourseCatalog(fromController: self, bottomBar: nil)
            }
            footer.sizeToFit()
        }
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
        if collectionController.courses.count <= 0 {
            hideSnackBar()
        }
    }
    
    func coursesTableChoseCourse(course: OEXCourse) {
        if let course_id = course.course_id {
            environment.router?.showCourseWithID(courseID: course_id, fromController: self, animated: true)
        }
        else {
            preconditionFailure("course without a course id")
        }
    }
    
    private func showWhatsNewIfNeeded() {
        if WhatsNewViewController.canShowWhatsNew(environment: environment as? RouterEnvironment) {
            environment.router?.showWhatsNew(fromController: self)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
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
}

// For testing use only
extension EnrolledCoursesViewController {
    var t_loaded: OEXStream<()> {
        return self.enrollmentFeed.output.map {_ in
            return ()
        }
    }
}
