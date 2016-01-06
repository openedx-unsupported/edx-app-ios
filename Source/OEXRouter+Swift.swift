//
//  OEXRouter+Swift.swift
//  edX
//
//  Created by Akiva Leffert on 5/7/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

// The router is an indirection point for navigation throw our app.

// New router logic should live here so it can be written in Swift.
// We should gradually migrate the existing router class here and then
// get rid of the objc version

enum CourseHTMLBlockSubkind {
    case Base
    case Problem
}

enum CourseBlockDisplayType {
    case Unknown
    case Outline
    case Unit
    case Video
    case HTML(CourseHTMLBlockSubkind)
    
    var isUnknown : Bool {
        switch self {
        case Unknown: return true
        default: return false
        }
    }
}

extension CourseBlock {
    
    var displayType : CourseBlockDisplayType {
        switch self.type {
        case .Unknown(_), .HTML: return multiDevice ? .HTML(.Base) : .Unknown
        case .Problem: return multiDevice ? .HTML(.Problem) : .Unknown
        case .Course: return .Outline
        case .Chapter: return .Outline
        case .Section: return .Outline
        case .Unit: return .Unit
        case let .Video(summary): return summary.onlyOnWeb ? .Unknown : .Video
        }
    }
}

extension OEXRouter {
    func showCoursewareForCourseWithID(courseID : String, fromController controller : UIViewController) {
        showContainerForBlockWithID(nil, type: CourseBlockDisplayType.Outline, parentID: nil, courseID : courseID, fromController: controller)
    }
    
    func unitControllerForCourseID(courseID : String, blockID : CourseBlockID?, initialChildID : CourseBlockID?) -> CourseContentPageViewController {
        let contentPageController = CourseContentPageViewController(environment: environment, courseID: courseID, rootID: blockID, initialChildID: initialChildID)
        return contentPageController
    }
    
    func showContainerForBlockWithID(blockID : CourseBlockID?, type : CourseBlockDisplayType, parentID : CourseBlockID?, courseID : CourseBlockID, fromController controller: UIViewController) {
        switch type {
        case .Outline:
            fallthrough
        case .Unit:
            let outlineController = controllerForBlockWithID(blockID, type: type, courseID: courseID)
            controller.navigationController?.pushViewController(outlineController, animated: true)
        case .HTML:
            fallthrough
        case .Video:
            fallthrough
        case .Unknown:
            let pageController = unitControllerForCourseID(courseID, blockID: parentID, initialChildID: blockID)
            if let delegate = controller as? CourseContentPageViewControllerDelegate {
                pageController.navigationDelegate = delegate
            }
            controller.navigationController?.pushViewController(pageController, animated: true)
        }
    }
    
    private func controllerForBlockWithID(blockID : CourseBlockID?, type : CourseBlockDisplayType, courseID : String) -> UIViewController {
        switch type {
            case .Outline:
                let outlineController = CourseOutlineViewController(environment: self.environment, courseID: courseID, rootID: blockID)
                return outlineController
        case .Unit:
            return unitControllerForCourseID(courseID, blockID: blockID, initialChildID: nil)
        case .HTML:
            let controller = HTMLBlockViewController(blockID: blockID, courseID : courseID, environment : environment)
            return controller
        case .Video:
            let controller = VideoBlockViewController(environment: environment, blockID: blockID, courseID: courseID)
            return controller
        case .Unknown:
            let controller = CourseUnknownBlockViewController(blockID: blockID, courseID : courseID, environment : environment)
            return controller
        }
    }
    
    func controllerForBlock(block : CourseBlock, courseID : String) -> UIViewController {
        return controllerForBlockWithID(block.blockID, type: block.displayType, courseID: courseID)
    }
    
    @objc(showMyCoursesAnimated:pushingCourseWithID:) func showMyCourses(animated animated: Bool = true, pushingCourseWithID courseID: String? = nil) {
        let controller = EnrolledCoursesViewController(environment: self.environment)
        showContentStackWithRootController(controller, animated: animated)
        if let courseID = courseID {
            self.showCourseWithID(courseID, fromController: controller, animated: false)
        }
    }
    
    func showFullScreenMessageViewControllerFromViewController(controller : UIViewController, message : String, bottomButtonTitle: String?) {
        let fullScreenViewController = FullScreenMessageViewController(message: message, bottomButtonTitle: bottomButtonTitle)
        controller.presentViewController(fullScreenViewController, animated: true, completion: nil)
    }
    
    func showDiscussionResponsesFromViewController(controller: UIViewController, courseID : String, threadID : String) {
        let storyboard = UIStoryboard(name: "DiscussionResponses", bundle: nil)
        let responsesViewController = storyboard.instantiateInitialViewController() as! DiscussionResponsesViewController
        responsesViewController.environment = environment
        responsesViewController.courseID = courseID
        responsesViewController.threadID = threadID
        controller.navigationController?.pushViewController(responsesViewController, animated: true)
    }
    
    func showDiscussionCommentsFromViewController(controller: UIViewController, courseID : String, response : DiscussionComment, closed : Bool) {
        let commentsVC = DiscussionCommentsViewController(environment: environment, courseID : courseID, responseItem: response, closed: closed)
        controller.navigationController?.pushViewController(commentsVC, animated: true)
    }
    
    func showDiscussionNewCommentFromController(controller: UIViewController, courseID : String, context: DiscussionNewCommentViewController.Context) {
        let newCommentViewController = DiscussionNewCommentViewController(environment: environment, courseID : courseID, context: context)
        let navigationController = UINavigationController(rootViewController: newCommentViewController)
        controller.presentViewController(navigationController, animated: true, completion: nil)
    }
    
    func showPostsFromController(controller : UIViewController, courseID : String, topic : DiscussionTopic) {
        let environment = PostsViewControllerEnvironment(networkManager: self.environment.networkManager, router: self, styles: self.environment.styles)
        let postsController = PostsViewController(environment: environment, courseID: courseID, topic: topic)
        controller.navigationController?.pushViewController(postsController, animated: true)
    }
    
    func showAllPostsFromController(controller : UIViewController, courseID : String, followedOnly following : Bool) {
        let environment = PostsViewControllerEnvironment(networkManager: self.environment.networkManager, router: self, styles: self.environment.styles)
        let postsController = PostsViewController(environment: environment, courseID: courseID, following : following)
        controller.navigationController?.pushViewController(postsController, animated: true)
    }
    
    func showPostsFromController(controller : UIViewController, courseID : String, queryString : String) {
        let environment = PostsViewControllerEnvironment(networkManager: self.environment.networkManager, router: self, styles: self.environment.styles)
        let postsController = PostsViewController(environment: environment, courseID: courseID, queryString : queryString)
        controller.navigationController?.pushViewController(postsController, animated: true)
    }
    
    func showDiscussionTopicsFromController(controller: UIViewController, courseID : String) {
        let topicsController = DiscussionTopicsViewController(environment: environment, courseID: courseID)
        controller.navigationController?.pushViewController(topicsController, animated: true)
    }

    func showDiscussionNewPostFromController(controller: UIViewController, courseID : String, selectedTopic : DiscussionTopic?) {
        let newPostController = DiscussionNewPostViewController(environment: environment, courseID: courseID, selectedTopic: selectedTopic)
        let navigationController = UINavigationController(rootViewController: newPostController)
        controller.presentViewController(navigationController, animated: true, completion: nil)
    }
    
    func showHandoutsFromController(controller : UIViewController, courseID : String) {
        let handoutsViewController = CourseHandoutsViewController(environment: environment, courseID: courseID)
        controller.navigationController?.pushViewController(handoutsViewController, animated: true)
    }

    func showProfileForUsername(controller: UIViewController? = nil, username : String, editable: Bool = true) {
        OEXAnalytics.sharedAnalytics().trackProfileViewed(username)
        let editable = self.environment.session.currentUser?.username == username
        let profileFeed = self.environment.dataManager.userProfileManager.feedForUser(username)
        let profileController = UserProfileViewController(environment: environment, feed: profileFeed, editable: editable)
        if let controller = controller {
            controller.navigationController?.pushViewController(profileController, animated: true)
        } else {
            self.showContentStackWithRootController(profileController, animated: true)
        }
    }
    
    func showProfileEditorFromController(controller : UIViewController) {
        guard let profile = environment.dataManager.userProfileManager.feedForCurrentUser().output.value else {
            return
        }
        let editController = UserProfileEditViewController(profile: profile, environment: environment)
        controller.navigationController?.pushViewController(editController, animated: true)
    }

    func showCertificate(url: NSURL, title: String?, fromController controller: UIViewController) {
        let c = CertificateViewController(environment: environment)
        c.title = title
        controller.navigationController?.pushViewController(c, animated: true)
        c.loadRequest(NSURLRequest(URL: url))
    }
    
    func showCourseWithID(courseID : String, fromController: UIViewController, animated: Bool = true) {
        let controller = CourseDashboardViewController(environment: self.environment, courseID: courseID)
        fromController.navigationController?.pushViewController(controller, animated: animated)
    }
    
    func showCourseCatalog() {
        if(environment.config.courseEnrollmentConfig()?.enabled ?? false) {
            let controller = OEXFindCoursesViewController()
            self.showContentStackWithRootController(controller, animated: true)
        }
        else if(environment.config.courseEnrollmentConfig()?.useNativeCourseDiscovery ?? false) {
            let controller = CourseCatalogViewController(environment: self.environment)
            self.showContentStackWithRootController(controller, animated: true)
        }
        else {
            let controller = OEXFindCourseInterstitialViewController()
            self.presentViewController(controller, completion: nil)
        }
        self.environment.analytics.trackUserFindsCourses()
    }
    
    func showCourseCatalogDetail(courseID: String, fromController: UIViewController) {
        let detailController = CourseCatalogDetailViewController(environment: environment, courseID: courseID)
        fromController.navigationController?.pushViewController(detailController, animated: true)
    }

    // MARK: - Debug
    func showDebugPane() {
        let debugMenu = DebugMenuViewController(environment: environment)
        showContentStackWithRootController(debugMenu, animated: true)
    }
}

