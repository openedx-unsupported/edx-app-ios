//
//  EnrolledCoursesViewController.swift
//  edX
//
//  Created by Akiva Leffert on 12/21/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

private var isUpgradeSnackbarShown = false
var isActionTakenOnUpgradeSnackBar: Bool = false

class EnrolledCoursesViewController : OfflineSupportViewController, CoursesTableViewControllerDelegate, PullRefreshControllerDelegate {
    
    typealias Environment = protocol<OEXAnalyticsProvider, OEXConfigProvider, DataManagerProvider, NetworkManagerProvider, ReachabilityProvider, OEXRouterProvider>
    
    private let environment : Environment
    private let tableController : CoursesTableViewController
    private let loadController = LoadStateViewController()
    private let refreshController = PullRefreshController()
    private let insetsController = ContentInsetsController()
    private let enrollmentFeed: Feed<[UserCourseEnrollment]?>
    private let userPreferencesFeed: Feed<UserPreference?>

    init(environment: Environment) {
        self.tableController = CoursesTableViewController(environment: environment, context: .EnrollmentList)
        self.enrollmentFeed = environment.dataManager.enrollmentManager.feed
        self.userPreferencesFeed = environment.dataManager.userPreferenceManager.feed
        self.environment = environment
        
        super.init(env: environment)
        self.navigationItem.title = Strings.myCourses
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.accessibilityIdentifier = "enrolled-courses-screen"

        addChildViewController(tableController)
        tableController.didMoveToParentViewController(self)
        self.loadController.setupInController(self, contentView: tableController.view)
        
        self.view.addSubview(tableController.view)
        tableController.view.snp_makeConstraints {make in
            make.edges.equalTo(self.view)
        }
        
        tableController.delegate = self
        
        self.view.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        
        refreshController.setupInScrollView(self.tableController.tableView)
        refreshController.delegate = self
        
        insetsController.setupInController(self, scrollView: tableController.tableView)
        insetsController.addSource(self.refreshController)

        // We visually separate each course card so we also need a little padding
        // at the bottom to match
        insetsController.addSource(
            ConstantInsetsSource(insets: UIEdgeInsets(top: 0, left: 0, bottom: StandardVerticalMargin, right: 0), affectsScrollIndicators: false)
        )
        
        self.enrollmentFeed.refresh()
        self.userPreferencesFeed.refresh()
        
        setupListener()
        setupFooter()
        setupObservers()
    }
    
    override func viewWillAppear(animated: Bool) {
        environment.analytics.trackScreenWithName(OEXAnalyticsScreenMyCourses)
        showVersionUpgradeSnackBarIfNecessary()
        super.viewWillAppear(animated)
    }
    
    override func reloadViewData() {
        refreshIfNecessary()
    }

    private func setupListener() {
        enrollmentFeed.output.listen(self) {[weak self] result in
            if !(self?.enrollmentFeed.output.active ?? false) {
                self?.refreshController.endRefreshing()
            }
            
            switch result {
            case let .Success(enrollments):
                if let enrollments = enrollments {
                    self?.tableController.courses = enrollments.flatMap { $0.course } ?? []
                    self?.tableController.tableView.reloadData()
                    self?.loadController.state = .Loaded
                    if enrollments.count <= 0 {
                        self?.enrollmentsEmptyState()
                    }
                }
                else {
                    self?.loadController.state = .Initial
                }
            case let .Failure(error):
                self?.loadController.state = LoadState.failed(error)
                if error.errorIsThisType(NSError.oex_outdatedVersionError()) {
                    self?.hideSnackBar()
                }
            }
        }
    }
    
    private func setupFooter() {
        if environment.config.courseEnrollmentConfig.isCourseDiscoveryEnabled() {
            let footer = EnrolledCoursesFooterView()
            footer.findCoursesAction = {[weak self] in
                self?.environment.router?.showCourseCatalog(nil)
            }
            footer.missingCoursesAction = {[weak self] in
                self?.showCourseNotListedAlert()
            }
            
            footer.sizeToFit()
            self.tableController.tableView.tableFooterView = footer
        }
        else {
            tableController.tableView.tableFooterView = UIView()
        }
    }
    
    private func enrollmentsEmptyState() {
        if !environment.config.courseEnrollmentConfig.isCourseDiscoveryEnabled() {
            let error = NSError.oex_errorWithCode(.Unknown, message: Strings.EnrollmentList.noEnrollment)
            loadController.state = LoadState.failed(error, icon: Icon.UnknownError)
        }
    }
    
    private func setupObservers() {
        let config = environment.config
        NSNotificationCenter.defaultCenter().oex_addObserver(self, name: OEXExternalRegistrationWithExistingAccountNotification) { (notification, observer, _) -> Void in
            let platform = config.platformName()
            let service = notification.object as? String ?? ""
            let message = Strings.externalRegistrationBecameLogin(platformName: platform, service: service)
            observer.showOverlayMessage(message)
        }
        
        NSNotificationCenter.defaultCenter().oex_addObserver(self, name: AppNewVersionAvailableNotification) { (notification, observer, _) -> Void in
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
    
    private func showCourseNotListedAlert() {
        let alertController = UIAlertController().showAlertWithTitle(nil, message: Strings.courseNotListed, cancelButtonTitle: nil, onViewController: self)
        alertController.addButtonWithTitle(Strings.ok, actionBlock: { (action) in
            dispatch_async(dispatch_get_main_queue(), { 
                UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self.navigationItem.leftBarButtonItem)
            })
        })
    }
    
    private func showVersionUpgradeSnackBarIfNecessary() {
        if let _ = VersionUpgradeInfoController.sharedController.latestVersion {
            var infoString = Strings.VersionUpgrade.newVersionAvailable
            if let _ = VersionUpgradeInfoController.sharedController.lastSupportedDateString {
                infoString = Strings.VersionUpgrade.deprecatedMessage
            }
            if !isUpgradeSnackbarShown || !isActionTakenOnUpgradeSnackBar {
                showVersionUpgradeSnackBar(infoString)
                isUpgradeSnackbarShown = true
            }
        }
        else {
            hideSnackBar()
        }
    }
    
    func coursesTableChoseCourse(course: OEXCourse) {
        if let course_id = course.course_id {
            self.environment.router?.showCourseWithID(course_id, fromController: self, animated: true)
        }
        else {
            preconditionFailure("course without a course id")
        }
    }
    
    func refreshControllerActivated(controller: PullRefreshController) {
        self.enrollmentFeed.refresh()
        self.userPreferencesFeed.refresh()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tableController.tableView.autolayoutFooter()
    }
}

// For testing use only
extension EnrolledCoursesViewController {
    var t_loaded: Stream<()> {
        return self.enrollmentFeed.output.map {_ in
            return ()
        }
    }
}
