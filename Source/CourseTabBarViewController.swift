//
//  CourseTabBarViewController.swift
//  edX
//
//  Created by Salman on 24/10/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

struct CoursesTabBarItem {
    let title: String
    let viewController: UIViewController
    let icon: Icon
    let detailText: String
    
}

class CourseTabBarViewController: UITabBarController, UITabBarControllerDelegate {
    
    public typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & NetworkManagerProvider & OEXRouterProvider & OEXInterfaceProvider & ReachabilityProvider & OEXSessionProvider & OEXStylesProvider
    
    
    private let courseID: String
    private let environment: Environment
    fileprivate var tabBarItems : [CoursesTabBarItem] = []
    fileprivate let loadController = LoadStateViewController()
    private let loadStateErrorController = CourseTabBarErrorViewController()
    private lazy var progressController : ProgressController = {
        ProgressController(owner: self, router: self.environment.router, dataInterface: self.environment.interface)
    }()
    
    fileprivate let courseStream = BackedStream<UserCourseEnrollment>()
    
    public init(environment: Environment, courseID: String) {
        self.environment = environment
        self.courseID = courseID
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Course Name"
        
        self.viewControllers = [loadStateErrorController]
        
        courseStream.backWithStream(environment.dataManager.enrollmentManager.streamForCourseWithID(courseID: courseID))
        courseStream.listen(self) {[weak self] in
            self?.resultLoaded(result: $0)
        }
        
        self.progressController.hideProgessView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    public func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController){
        self.navigationItem.title = viewController.navigationItem.title
    }
    
    func addShareButton(enrollment: UserCourseEnrollment) {
        let shareButton = UIBarButtonItem(image: UIImage(named: "shareCourse.png"), style: UIBarButtonItemStyle.plain, target: self, action: nil)
        shareButton.oex_setAction { [weak self] in
            self?.shareCourse(course: enrollment.course)
        }        
        navigationItem.rightBarButtonItems = [shareButton]
    }
    
    func addNavigationItems(enrollment: UserCourseEnrollment) {
        if enrollment.course.course_about != nil || environment.config.courseSharingEnabled {
            addShareButton(enrollment: enrollment)
        }
        navigationItem.rightBarButtonItems?.append(self.progressController.navigationItem())
    }
    
    func prepareTabViewData(enrollment: UserCourseEnrollment) {
        
        tabBarItems = []
        
        var item = CoursesTabBarItem(title: Strings.Dashboard.courseCourseware, viewController: CourseOutlineViewController(environment: environment, courseID: courseID, rootID: nil, forMode: CourseOutlineMode.Full), icon: Icon.Courseware, detailText: "")
        tabBarItems.append(item)
        
        if environment.config.isCourseVideosEnabled {
           item = CoursesTabBarItem(title: Strings.Dashboard.courseVideos, viewController: CourseOutlineViewController(environment: environment, courseID: courseID, rootID: nil, forMode: CourseOutlineMode.Video), icon: Icon.CourseVideos, detailText: "")
            tabBarItems.append(item)
        }
        
        if shouldShowDiscussions(course: enrollment.course) {
            item = CoursesTabBarItem(title: Strings.Dashboard.courseDiscussion, viewController: DiscussionTopicsViewController(environment: environment, courseID: courseID), icon: Icon.Discussions, detailText: "")
            tabBarItems.append(item)
        }
        
        if environment.config.courseDatesEnabled {
            item = CoursesTabBarItem(title: Strings.Dashboard.courseImportantDates, viewController: CourseDatesViewController(environment: environment , courseID: courseID), icon: Icon.Calendar, detailText: "")
            tabBarItems.append(item)
        }

        if shouldShowHandouts(course: enrollment.course) {
            item = CoursesTabBarItem(title: Strings.Dashboard.courseHandouts, viewController: CourseHandoutsViewController(environment: environment, courseID: courseID), icon: Icon.Handouts, detailText: Strings.Dashboard.courseHandoutsDetail)
            tabBarItems.append(item)
        }
        
        if environment.config.isAnnouncementsEnabled {
            item = CoursesTabBarItem(title: Strings.Dashboard.courseAnnouncements, viewController: CourseAnnouncementsViewController(environment: environment, courseID: courseID), icon:Icon.Announcements, detailText: Strings.Dashboard.courseAnnouncementsDetail)
            tabBarItems.append(item)
        }
        
        if tabBarItems.count > 4 {
            var views = Array(tabBarItems[0..<4])
            let moreViews = Array(tabBarItems[4..<tabBarItems.count])
            item = CoursesTabBarItem(title:Strings.resourses, viewController: CourseDashboardAdditionalViewController(environment: environment, courseID: courseID, enrollment: enrollment, cellItems: moreViews), icon: Icon.EllipsisHorizontal, detailText: "")
            views.append(item)
            loadTabBarViewControllers(tabBarItems: views)
        }
        else {
            loadTabBarViewControllers(tabBarItems: tabBarItems)
        }
    }
    
    func loadTabBarViewControllers(tabBarItems: [CoursesTabBarItem]) {
        var views:[UIViewController] = []
        for tabBarItem in tabBarItems {
            let controller = tabBarItem.viewController
            controller.tabBarItem = UITabBarItem(title:tabBarItem.title, image:tabBarItem.icon.imageWithFontSize(size: 20), selectedImage: tabBarItem.icon.imageWithFontSize(size: 20))
            views.append(controller)
        }
        self.viewControllers = views
    }
    
    func loadedCourseWithEnrollment(enrollment: UserCourseEnrollment) {
        verifyAccessForCourse(enrollment: enrollment)
    }
    
    private func resultLoaded(result : Result<UserCourseEnrollment>) {
        switch result {
        case let Result.success(enrollment):
            loadedCourseWithEnrollment(enrollment: enrollment)
        case let Result.failure(error):
            if !courseStream.active {
                // enrollment list is cached locally, so if the stream is still active we may yet load the course
                // don't show failure until the stream is done
                loadStateErrorController.loadController.state = LoadState.failed(error: error)
            }
        }
    }

    private func verifyAccessForCourse(enrollment: UserCourseEnrollment){
        if let access = enrollment.course.courseware_access, !access.has_access {
         loadStateErrorController.loadController.state = LoadState.failed(error: OEXCoursewareAccessError(coursewareAccess: access, displayInfo: enrollment.course.start_display_info), icon: Icon.UnknownError)
            setTabBarVisible(visible: false, animated: true)
        }
        else {
            loadStateErrorController.loadController.state = .Loaded
            prepareTabViewData(enrollment: enrollment)
            addNavigationItems(enrollment: enrollment)
        }
        
    }
    
    private func shouldShowDiscussions(course: OEXCourse) -> Bool {
        let canShowDiscussions = self.environment.config.discussionsEnabled
        let courseHasDiscussions = course.hasDiscussionsEnabled
        return canShowDiscussions && courseHasDiscussions
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
            self.present(controller, animated: true, completion: nil)
        }
    }
    
    func setTabBarVisible(visible: Bool, animated: Bool) {
        //* This cannot be called before viewDidLayoutSubviews(), because the frame is not set before this time
        
        // bail if the current state matches the desired state
        if (isTabBarVisible == visible) { return }
        
        // get a frame calculation ready
        let frame = self.tabBar.frame
        let height = frame.size.height
        let offsetY = (visible ? -height : height)
        
        // zero duration means no animation
        let duration: TimeInterval = (animated ? 0.3 : 0.0)
        
        //  animate the tabBar
        UIView.animate(withDuration: duration) {
            self.tabBar.frame = frame.offsetBy(dx: 0, dy: offsetY)
            return
        }
    }
    
    var isTabBarVisible: Bool {
        return self.tabBar.frame.origin.y < self.view.frame.maxY
    }

}

// MARK: Testing
extension CourseTabBarViewController {
    
    func t_canVisitDiscussions() -> Bool {
        return self.tabBarItems.firstIndexMatching({ (item: CoursesTabBarItem) in return item.icon == .Discussions }) != nil
    }

    func t_canVisitHandouts() -> Bool {
        return self.tabBarItems.firstIndexMatching({ (item: CoursesTabBarItem) in return item.icon == .Handouts }) != nil
    }

    func t_canVisitAnnouncements() -> Bool {
        return self.tabBarItems.firstIndexMatching({ (item: CoursesTabBarItem) in return item.icon == .Announcements }) != nil
    }

    var t_loaded : OEXStream<()> {
        return self.courseStream.map {_ in () }
    }
    
}
