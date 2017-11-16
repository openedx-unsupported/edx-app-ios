//
//  CourseDashboardTabBarViewController.swift
//  edX
//
//  Created by Salman on 24/10/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

// CourseDashboardTabBarItem represent each tab in tabBarViewController
struct CourseDashboardTabBarItem {
    let title: String
    let viewController: UIViewController
    let icon: Icon
    let detailText: String
}

class CourseDashboardTabBarViewController: UITabBarController, UITabBarControllerDelegate {
    
     typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & NetworkManagerProvider & OEXRouterProvider & OEXInterfaceProvider & ReachabilityProvider & OEXSessionProvider & OEXStylesProvider
    
    private let courseID: String
    private let environment: Environment
    fileprivate var tabBarItems : [CourseDashboardTabBarItem] = []
    fileprivate let loadStateController: CourseTabBarLoadStateViewController
    private lazy var progressController : ProgressController = {
        ProgressController(owner: self, router: self.environment.router, dataInterface: self.environment.interface)
    }()
    
    fileprivate let courseStream = BackedStream<UserCourseEnrollment>()
    
    init(environment: Environment, courseID: String) {
        self.environment = environment
        self.courseID = courseID
        loadStateController = CourseTabBarLoadStateViewController(environment: environment)
        
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
    
    private func addShareButton(withCourse course: OEXCourse) {
        let shareButton = UIBarButtonItem(image: UIImage(named: "shareCourse.png"), style: UIBarButtonItemStyle.plain, target: self, action: nil)
        shareButton.accessibilityLabel = Strings.Accessibility.shareACourse
        shareButton.oex_setAction { [weak self] in
            self?.shareCourse(course: course)
        }        
        navigationItem.rightBarButtonItems = [shareButton]
    }
    
    private func addNavigationItems(withCourse course: OEXCourse) {
        if course.course_about != nil && environment.config.courseSharingEnabled {
            addShareButton(withCourse: course)
        }
        navigationItem.rightBarButtonItems?.append(progressController.navigationItem())
    }
    
    private func prepareTabViewData(withCourse course: OEXCourse) {
        
        tabBarItems = []
        
        var item = CourseDashboardTabBarItem(title: Strings.Dashboard.courseCourseware, viewController: CourseOutlineViewController(environment: environment, courseID: courseID, rootID: nil, forMode: CourseOutlineMode.Full), icon: Icon.Courseware, detailText: Strings.Dashboard.courseCourseDetail)
        tabBarItems.append(item)
        
        if environment.config.isCourseVideosEnabled {
           item = CourseDashboardTabBarItem(title: Strings.Dashboard.courseVideos, viewController: CourseOutlineViewController(environment: environment, courseID: courseID, rootID: nil, forMode: CourseOutlineMode.Video), icon: Icon.CourseVideos, detailText: Strings.Dashboard.courseVideosDetail)
            tabBarItems.append(item)
        }
        
        if shouldShowDiscussions(course: course) {
            item = CourseDashboardTabBarItem(title: Strings.Dashboard.courseDiscussion, viewController: DiscussionTopicsViewController(environment: environment, courseID: courseID), icon: Icon.Discussions, detailText: Strings.Dashboard.courseDiscussionDetail)
            tabBarItems.append(item)
        }
        
        if environment.config.courseDatesEnabled {
            item = CourseDashboardTabBarItem(title: Strings.Dashboard.courseImportantDates, viewController: CourseDatesViewController(environment: environment , courseID: courseID), icon: Icon.Calendar, detailText: Strings.Dashboard.courseImportantDatesDetail)
            tabBarItems.append(item)
        }

        if shouldShowHandouts(course: course) {
            item = CourseDashboardTabBarItem(title: Strings.Dashboard.courseHandouts, viewController: CourseHandoutsViewController(environment: environment, courseID: courseID), icon: Icon.Handouts, detailText: Strings.Dashboard.courseHandoutsDetail)
            tabBarItems.append(item)
        }
        
        if environment.config.isAnnouncementsEnabled {
            item = CourseDashboardTabBarItem(title: Strings.Dashboard.courseAnnouncements, viewController: CourseAnnouncementsViewController(environment: environment, courseID: courseID), icon:Icon.Announcements, detailText: Strings.Dashboard.courseAnnouncementsDetail)
            tabBarItems.append(item)
        }
        
        if tabBarItems.count > 4 {
            var items = Array(tabBarItems[0..<4])
            let additionalItems = Array(tabBarItems[4..<tabBarItems.count])
            item = CourseDashboardTabBarItem(title:Strings.resourses, viewController: CourseDashboardAdditionalViewController(environment: environment, cellItems: additionalItems), icon: Icon.MoreOptionsIcon, detailText: "")
            
            items.append(item)
            loadTabBarViewControllers(tabBarItems: items)
        }
        else {
            loadTabBarViewControllers(tabBarItems: tabBarItems)
        }
    }
    
    private func loadTabBarViewControllers(tabBarItems: [CourseDashboardTabBarItem]) {
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
                analytics.trackCourseShared(courseID, url: urlString, socialTarget: analyticsType)
            })
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


extension CourseDashboardTabBarViewController {
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController){
        navigationItem.title = viewController.navigationItem.title
    }
}

// MARK: Testing
extension CourseDashboardTabBarViewController {

    func t_canVisitDiscussions() -> Bool {
        return tabBarItems.firstIndexMatching({ (item: CourseDashboardTabBarItem) in return item.icon == .Discussions }) != nil
    }

    func t_canVisitHandouts() -> Bool {
        return tabBarItems.firstIndexMatching({ (item: CourseDashboardTabBarItem) in return item.icon == .Handouts }) != nil
    }

    func t_canVisitAnnouncements() -> Bool {
        return tabBarItems.firstIndexMatching({ (item: CourseDashboardTabBarItem) in return item.icon == .Announcements }) != nil
    }
    
    var t_state : LoadState {
        return loadStateController.loadController.state
    }

    var t_loaded : OEXStream<()> {
        return courseStream.map {_ in () }
    }
    
    func t_items() -> [CourseDashboardTabBarItem] {
        return tabBarItems
    }
}
