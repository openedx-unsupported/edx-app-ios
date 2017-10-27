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
        self.loadViewControllers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.delegate = self
    }
    
    func prepareTabViewData() {
      
        if environment.config.isCourseVideosEnabled {
    
    //        cellItems.append(item)
        }
        //if shouldShowDiscussions(course: <#T##OEXCourse#>)
        
       
        if environment.config.isAnnouncementsEnabled {
      
        }
        
        if environment.config.courseDatesEnabled {
      
        }
    }
    
    private func shouldShowDiscussions(course: OEXCourse) -> Bool {
        let canShowDiscussions = self.environment.config.discussionsEnabled
        let courseHasDiscussions = course.hasDiscussionsEnabled
        return canShowDiscussions && courseHasDiscussions
    }
    
    func loadViewControllers() {
        guard let router = environment.router else { return }
        
        let courseViewController = CourseOutlineViewController(environment: router.environment, courseID: courseID, rootID: nil, forMode: CourseOutlineMode.Full)
        let videoViewController = CourseOutlineViewController(environment: router.environment, courseID: courseID, rootID: nil, forMode: CourseOutlineMode.Video)
        let discussionViewController = DiscussionTopicsViewController(environment: router.environment, courseID: courseID)
        let courseDatesViewController = CourseDatesViewController(environment:router.environment , courseID: courseID)
        
        let moreOptionsViewController = router.controllerForBlockWithID(blockID: nil, type: CourseBlockDisplayType.Outline, courseID: courseID, forMode: .Video)
        
        
        courseViewController.tabBarItem = UITabBarItem(title:Strings.Dashboard.courseCourseware, image: Icon.Courseware.imageWithFontSize(size: 20), selectedImage: Icon.Courseware.imageWithFontSize(size: 20))
        
        videoViewController.tabBarItem = UITabBarItem(title:Strings.Dashboard.courseVideos, image: Icon.CourseVideos.imageWithFontSize(size: 20), selectedImage: Icon.CourseVideos.imageWithFontSize(size: 20))
        
        discussionViewController.tabBarItem = UITabBarItem(title:Strings.Dashboard.courseDiscussion, image: Icon.Discussions.imageWithFontSize(size: 20), selectedImage: Icon.Discussions.imageWithFontSize(size: 20))
        
        courseDatesViewController.tabBarItem = UITabBarItem(title:Strings.Dashboard.courseImportantDates, image: Icon.Calendar .imageWithFontSize(size: 20), selectedImage: Icon.Calendar.imageWithFontSize(size: 20))
        
        moreOptionsViewController.tabBarItem = UITabBarItem(title: "", image: Icon.EllipsisHorizontal.imageWithFontSize(size: 20), selectedImage: Icon.EllipsisHorizontal.imageWithFontSize(size: 20))
        
        self.viewControllers = [courseViewController, videoViewController, discussionViewController, courseDatesViewController, moreOptionsViewController]
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
    
    


}
