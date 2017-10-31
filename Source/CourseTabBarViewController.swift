//
//  CourseTabBarViewController.swift
//  edX
//
//  Created by Salman on 24/10/2017.
//  Copyright © 2017 edX. All rights reserved.
//

import UIKit

class CourseTabBarViewController: UITabBarController, UITabBarControllerDelegate {
    
    public typealias Environment = OEXAnalyticsProvider & OEXConfigProvider & DataManagerProvider & NetworkManagerProvider & OEXRouterProvider & OEXInterfaceProvider & OEXRouterProvider
    private let courseID: String
    private let environment: Environment
    private var tabBatviews : [UIViewController] = []
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
    
    override public var shouldAutorotate: Bool {
        return true
    }
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .landscapeLeft
    }
    
    public func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController){
        self.navigationItem.title = viewController.navigationItem.title
    }
    
    func addShareButton(enrollment: UserCourseEnrollment) {
        
        let shareButton = UIBarButtonItem(image: Icon.shareAlt.imageWithFontSize(size: 20), style: UIBarButtonItemStyle.plain, target: self, action: nil)
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
        
        guard let router = environment.router else { return }
        tabBatviews = []
        let courseViewController = CourseOutlineViewController(environment: router.environment, courseID: courseID, rootID: nil, forMode: CourseOutlineMode.Full)
        courseViewController.tabBarItem = UITabBarItem(title:Strings.Dashboard.courseCourseware, image: Icon.Courseware.imageWithFontSize(size: 20), selectedImage: Icon.Courseware.imageWithFontSize(size: 20))
        tabBatviews.append(courseViewController)
        
        if environment.config.isCourseVideosEnabled {
            let videoViewController = CourseOutlineViewController(environment: router.environment, courseID: courseID, rootID: nil, forMode: CourseOutlineMode.Video)
            videoViewController.tabBarItem = UITabBarItem(title:Strings.Dashboard.courseVideos, image: Icon.CourseVideos.imageWithFontSize(size: 20), selectedImage: Icon.CourseVideos.imageWithFontSize(size: 20))
            tabBatviews.append(videoViewController)
        }
        
        if shouldShowDiscussions(course: enrollment.course) {
            let discussionViewController = DiscussionTopicsViewController(environment: router.environment, courseID: courseID)
            discussionViewController.tabBarItem = UITabBarItem(title:Strings.Dashboard.courseDiscussion, image: Icon.Discussions.imageWithFontSize(size: 20), selectedImage: Icon.Discussions.imageWithFontSize(size: 20))
            tabBatviews.append(discussionViewController)
        }
        
        if environment.config.courseDatesEnabled {
            let courseDatesViewController = CourseDatesViewController(environment:router.environment , courseID: courseID)
            courseDatesViewController.tabBarItem = UITabBarItem(title:Strings.Dashboard.courseImportantDates, image: Icon.Calendar .imageWithFontSize(size: 20), selectedImage: Icon.Calendar.imageWithFontSize(size: 20))
            tabBatviews.append(courseDatesViewController)
        }

        if shouldShowHandouts(course: enrollment.course) {
            let courseHandoutsViewController = CourseHandoutsViewController(environment: router.environment, courseID: courseID)
            courseHandoutsViewController.tabBarItem = UITabBarItem(title:Strings.Dashboard.courseHandouts , image: Icon.Handouts.imageWithFontSize(size: 20), selectedImage: Icon.Handouts.imageWithFontSize(size: 20))
            tabBatviews.append(courseHandoutsViewController)
        }
        
        if environment.config.isAnnouncementsEnabled {
            let courseAnnouncementViewController = CourseAnnouncementsViewController(environment: router.environment, courseID: courseID)
            courseAnnouncementViewController.tabBarItem = UITabBarItem(title:Strings.Dashboard.courseAnnouncements, image: Icon.Announcements.imageWithFontSize(size: 20), selectedImage: Icon.Announcements .imageWithFontSize(size: 20))
            tabBatviews.append(courseAnnouncementViewController)
        }
        
        if tabBatviews.count > 4 {
            var views = Array(tabBatviews[0..<4])
            let courseDashboardAdditionalViewController = CourseDashboardAdditionalViewController(environment: router.environment, courseID: courseID, enrollment: enrollment)
            courseDashboardAdditionalViewController.tabBarItem = UITabBarItem(title: "Resources", image: Icon.EllipsisHorizontal.imageWithFontSize(size: 20), selectedImage: Icon.EllipsisHorizontal.imageWithFontSize(size: 20))
            views.append(courseDashboardAdditionalViewController)
            self.viewControllers = views
        }
        else {
            self.viewControllers = tabBatviews
        }
    }
    
    func loadedCourseWithEnrollment(enrollment: UserCourseEnrollment) {
        prepareTabViewData(enrollment: enrollment)
        addNavigationItems(enrollment: enrollment)
    }
    
    private func resultLoaded(result : Result<UserCourseEnrollment>) {
        switch result {
        case let Result.success(enrollment):
            loadedCourseWithEnrollment(enrollment: enrollment)
        case let Result.failure(error):
            if !courseStream.active {
                // enrollment list is cached locally, so if the stream is still active we may yet load the course
                // don't show failure until the stream is done
                //self.loadController.state = LoadState.failed(error: error)
            }
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
}
