//
//  CourseDashboardViewController.swift
//  edX
//
//  Created by Salman on 24/10/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

class CourseDashboardViewController: UITabBarController, UITabBarControllerDelegate, InterfaceOrientationOverriding {
    
     typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & NetworkManagerProvider & OEXRouterProvider & OEXInterfaceProvider & ReachabilityProvider & OEXSessionProvider & OEXStylesProvider
    
    private let courseID: String
    fileprivate var course: OEXCourse?
    private let environment: Environment
    fileprivate var tabBarItems : [TabBarItem] = []
    fileprivate let loadStateController: CourseDashboardLoadStateViewController
    private lazy var progressController : ProgressController = {
        ProgressController(owner: self, router: self.environment.router, dataInterface: self.environment.interface)
    }()
    private let shareButton = UIButton(frame: CGRect(x: 0, y: 0, width: 26, height: 26))
    
    fileprivate let courseStream = BackedStream<UserCourseEnrollment>()
    
    init(environment: Environment, courseID: String) {
        self.environment = environment
        self.courseID = courseID
        loadStateController = CourseDashboardLoadStateViewController(environment: environment)
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        viewControllers = [loadStateController]
        courseStream.backWithStream(environment.dataManager.enrollmentManager.streamForCourseWithID(courseID: courseID))
        courseStream.listen(self) {[weak self] in
            self?.resultLoaded(result: $0)
        }
        delegate = self
        progressController.hideProgessView()
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
    
    fileprivate func addNavigationItems(withCourse course: OEXCourse) {
        var navigationItems: [UIBarButtonItem] = []
        if course.course_about != nil && environment.config.courseSharingEnabled {
            let shareImage = UIImage(named: "shareCourse.png")?.withRenderingMode(.alwaysTemplate)
            shareButton.setImage(shareImage, for: .normal)
            shareButton.tintColor = environment.styles.primaryBaseColor()
            shareButton.accessibilityLabel = Strings.Accessibility.shareACourse
            shareButton.oex_removeAllActions()
            shareButton.oex_addAction({[weak self] _ in
                self?.shareCourse(course: course)
                }, for: .touchUpInside)
            
            let shareItem = UIBarButtonItem(customView: shareButton)
            navigationItems.append(shareItem)
        }
        if let controller = selectedViewController as? CourseOutlineViewController, controller.courseOutlineMode == .full {
            navigationItems.append(progressController.navigationItem())
        }
        navigationItem.rightBarButtonItems = navigationItems
    }
    
    private func prepareTabViewData(withCourse course: OEXCourse) {
        
        tabBarItems = []
        
        var item = TabBarItem(title: Strings.Dashboard.courseCourseware, viewController: CourseOutlineViewController(environment: environment, courseID: courseID, rootID: nil, forMode: .full), icon: Icon.Courseware, detailText: Strings.Dashboard.courseCourseDetail)
        tabBarItems.append(item)
        
        if environment.config.isCourseVideosEnabled {
           item = TabBarItem(title: Strings.Dashboard.courseVideos, viewController: CourseOutlineViewController(environment: environment, courseID: courseID, rootID: nil, forMode: .video), icon: Icon.CourseVideos, detailText: Strings.Dashboard.courseVideosDetail)
            tabBarItems.append(item)
        }
        
        if shouldShowDiscussions(course: course) {
            item = TabBarItem(title: Strings.Dashboard.courseDiscussion, viewController: DiscussionTopicsViewController(environment: environment, courseID: courseID), icon: Icon.Discussions, detailText: Strings.Dashboard.courseDiscussionDetail)
            tabBarItems.append(item)
        }
        
        if environment.config.courseDatesEnabled {
            item = TabBarItem(title: Strings.Dashboard.courseImportantDates, viewController: CourseDatesViewController(environment: environment , courseID: courseID), icon: Icon.Calendar, detailText: Strings.Dashboard.courseImportantDatesDetail)
            tabBarItems.append(item)
        }

        if shouldShowHandouts(course: course) {
            item = TabBarItem(title: Strings.Dashboard.courseHandouts, viewController: CourseHandoutsViewController(environment: environment, courseID: courseID), icon: Icon.Handouts, detailText: Strings.Dashboard.courseHandoutsDetail)
            tabBarItems.append(item)
        }
        
        if environment.config.isAnnouncementsEnabled {
            item = TabBarItem(title: Strings.Dashboard.courseAnnouncements, viewController: CourseAnnouncementsViewController(environment: environment, courseID: courseID), icon:Icon.Announcements, detailText: Strings.Dashboard.courseAnnouncementsDetail)
            tabBarItems.append(item)
        }
        
        if tabBarItems.count > 4 {
            var items = Array(tabBarItems[0..<4])
            let additionalItems = Array(tabBarItems[4..<tabBarItems.count])
            item = TabBarItem(title:Strings.resourses, viewController: AdditionalTabBarViewController(environment: environment, cellItems: additionalItems), icon: Icon.MoreOptionsIcon, detailText: "")
            
            items.append(item)
            loadTabBarViewControllers(tabBarItems: items)
        }
        else {
            loadTabBarViewControllers(tabBarItems: tabBarItems)
        }
    }
    
    private func loadTabBarViewControllers(tabBarItems: [TabBarItem]) {
        var controllers :[UIViewController] = []
        for tabBarItem in tabBarItems {
            let controller = tabBarItem.viewController
            controller.tabBarItem = UITabBarItem(title:tabBarItem.title, image:tabBarItem.icon.imageWithFontSize(size: 20), selectedImage: tabBarItem.icon.imageWithFontSize(size: 20))
            controllers.append(controller)
        }
        viewControllers = controllers
    }
    
    private func loadedCourse(withCourse course: OEXCourse) {
        title = course.name
        verifyAccess(forCourse: course)
    }
    
    private func resultLoaded(result : Result<UserCourseEnrollment>) {
        switch result {
        case let Result.success(enrollment):
            course = enrollment.course
            loadedCourse(withCourse: enrollment.course)
        case let Result.failure(error):
            if !courseStream.active {
                // enrollment list is cached locally, so if the stream is still active we may yet load the course
                // don't show failure until the stream is done
                loadStateController.loadController.state = LoadState.failed(error: error)
            }
        }
    }

    private func verifyAccess(forCourse course: OEXCourse){
        if let access = course.courseware_access, !access.has_access {
         loadStateController.loadController.state = LoadState.failed(error: OEXCoursewareAccessError(coursewareAccess: access, displayInfo: course.start_display_info), icon: Icon.UnknownError)
            setTabBarVisibility(visible: false, animated: true)
        }
        else {
            loadStateController.loadController.state = .Loaded
            prepareTabViewData(withCourse: course)
            addNavigationItems(withCourse: course)
        }
    }
    
    private func shouldShowDiscussions(course: OEXCourse) -> Bool {
        return environment.config.discussionsEnabled && course.hasDiscussionsEnabled
    }
    
    private func shouldShowHandouts(course: OEXCourse) -> Bool {
        return !(course.course_handouts?.isEmpty ?? true)
    }
    
    private func shareCourse(course: OEXCourse) {
        if let urlString = course.course_about, let url = NSURL(string: urlString) {
            let analytics = environment.analytics
            let courseID = self.courseID
            let controller = shareHashtaggedTextAndALink(textBuilder: { hashtagOrPlatform in
                Strings.shareACourse(platformName: hashtagOrPlatform)
            }, url: url, utmParams: course.courseShareUtmParams, analyticsCallback: { analyticsType in
                analytics.trackCourseShared(courseID: courseID, url: urlString, type: analyticsType)
            })
            controller.configurePresentationController(withSourceView: shareButton)
            present(controller, animated: true, completion: nil)
        }
    }    
}

extension UITabBarController {
    
    func setTabBarVisibility(visible: Bool, animated: Bool) {
        //* This cannot be called before viewDidLayoutSubviews(), because the frame is not set before this time
        
        // bail if the current state matches the desired state
        if (isTabBarVisible == visible) { return }
        
        // get a frame calculation ready
        let frame = tabBar.frame
        let height = frame.size.height
        let offsetY = (visible ? -height : height)
        
        // zero duration means no animation
        let duration: TimeInterval = (animated ? 0.4 : 0.0)
        
        //  animate the tabBar
        UIView.animate(withDuration: duration) {[weak self] in
            self?.tabBar.frame = frame.offsetBy(dx: 0, dy: offsetY)
        }
    }
    
    private var isTabBarVisible: Bool {
        return tabBar.frame.origin.y < self.view.frame.maxY
    }
}


extension CourseDashboardViewController {
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController){
        navigationItem.title = viewController.navigationItem.title
        if let course = course {
            addNavigationItems(withCourse: course)
        }
    }
}

// MARK: Testing
extension CourseDashboardViewController {

    func t_canVisitDiscussions() -> Bool {
        return tabBarItems.firstIndexMatching({ (item: TabBarItem) in return item.icon == .Discussions }) != nil
    }

    func t_canVisitHandouts() -> Bool {
        return tabBarItems.firstIndexMatching({ (item: TabBarItem) in return item.icon == .Handouts }) != nil
    }

    func t_canVisitAnnouncements() -> Bool {
        return tabBarItems.firstIndexMatching({ (item: TabBarItem) in return item.icon == .Announcements }) != nil
    }
    
    var t_state : LoadState {
        return loadStateController.loadController.state
    }

    var t_loaded : OEXStream<()> {
        return courseStream.map {_ in () }
    }
    
    func t_items() -> [TabBarItem] {
        return tabBarItems
    }
}
