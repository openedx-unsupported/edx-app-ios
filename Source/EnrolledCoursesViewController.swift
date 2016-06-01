//
//  EnrolledCoursesViewController.swift
//  edX
//
//  Created by Akiva Leffert on 12/21/15.
//  Copyright © 2015 edX. All rights reserved.
//

import Foundation

class EnrolledCoursesViewController : WarningViewController, CoursesTableViewControllerDelegate, PullRefreshControllerDelegate {
    
    typealias Environment = protocol<OEXAnalyticsProvider, OEXConfigProvider, DataManagerProvider, NetworkManagerProvider, ReachabilityProvider, OEXRouterProvider>
    
    private let environment : Environment
    private let tableController : CoursesTableViewController
    private let loadController = LoadStateViewController()
    private let refreshController = PullRefreshController()
    private let insetsController = ContentInsetsController()
    private let enrollmentFeed: Feed<[UserCourseEnrollment]?>
    private var shownOfflineInfoHeader = false
    
    init(environment: Environment) {
        self.tableController = CoursesTableViewController(environment: environment, context: .EnrollmentList)
        self.enrollmentFeed = environment.dataManager.enrollmentManager.feed
        self.environment = environment
        super.init(nibName: nil, bundle: nil)

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
        
        contentView.addSubview(tableController.view)
        tableController.view.snp_makeConstraints {make in
            make.edges.equalTo(contentView)
        }
        
        tableController.delegate = self
        
        self.view.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        
        refreshController.setupInScrollView(self.tableController.tableView)
        refreshController.delegate = self
        
        insetsController.setupInController(self, scrollView: tableController.tableView)
        insetsController.addSource(self.refreshController)
//        insetsController.supportVersionUpgrade()
//        insetsController.supportOfflineMode(environment.reachability)

        // We visually separate each course card so we also need a little padding
        // at the bottom to match
        insetsController.addSource(
            ConstantInsetsSource(insets: UIEdgeInsets(top: 0, left: 0, bottom: StandardVerticalMargin, right: 0), affectsScrollIndicators: false)
        )
        
        self.enrollmentFeed.refresh()
        
        setupListener()
        setupFooter()
        setupObservers()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        environment.analytics.trackScreenWithName(OEXAnalyticsScreenMyCourses)
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
                }
                else {
                    self?.loadController.state = .Initial
                }
            case let .Failure(error):
                self?.loadController.state = LoadState.failed(error)
            }
        }
    }
    
    private func setupFooter() {
        let footer = EnrolledCoursesFooterView()
        footer.findCoursesAction = {[weak self] in
            self?.environment.router?.showCourseCatalog()
        }
        footer.missingCoursesAction = {[weak self] in
            self?.showCourseNotListedScreen()
        }
        
        footer.sizeToFit()
        self.tableController.tableView.tableFooterView = footer
    }
    
    private func setupObservers() {
        let config = environment.config
        NSNotificationCenter.defaultCenter().oex_addObserver(self, name: OEXExternalRegistrationWithExistingAccountNotification) { (notification, observer, _) -> Void in
            let platform = config.platformName()
            let service = notification.object as? String ?? ""
            let message = Strings.externalRegistrationBecameLogin(platformName: platform, service: service)
            observer.showOverlayMessage(message)
        }
        
        NSNotificationCenter.defaultCenter().oex_addObserver(self, name: kReachabilityChangedNotification) { (notification, observer, _) -> Void in
            observer.refreshIfNecessary()
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
    
    private func showCourseNotListedScreen() {
        environment.router?.showFullScreenMessageViewControllerFromViewController(self, message: Strings.courseNotListed, bottomButtonTitle: Strings.close)
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
