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
        case .Video(_): return .Video
        }
    }
}

extension OEXRouter {
    func showCoursewareForCourseWithID(courseID : String, fromController controller : UIViewController) {
        showContainerForBlockWithID(nil, type: CourseBlockDisplayType.Outline, parentID: nil, courseID : courseID, fromController: controller)
    }
    
    func unitControllerForCourseID(courseID : String, blockID : CourseBlockID?, initialChildID : CourseBlockID?) -> CourseContentPageViewController {
        let environment = CourseContentPageViewController.Environment(
            analytics: self.environment.analytics,
            dataManager: self.environment.dataManager,
            router: self,
            styles : self.environment.styles)
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
                let environment = CourseOutlineViewController.Environment(
                    analytics : self.environment.analytics,
                    dataManager: self.environment.dataManager,
                    networkManager : self.environment.networkManager,
                    reachability : InternetReachability(), router: self,
                    styles : self.environment.styles)
                let outlineController = CourseOutlineViewController(environment: environment, courseID: courseID, rootID: blockID)
                return outlineController
        case .Unit:
            return unitControllerForCourseID(courseID, blockID: blockID, initialChildID: nil)
        case .HTML:
            let environment = HTMLBlockViewController.Environment(config : self.environment.config, courseDataManager : self.environment.dataManager.courseDataManager, session : self.environment.session, styles : self.environment.styles)
            let controller = HTMLBlockViewController(blockID: blockID, courseID : courseID, environment : environment)
            return controller
        case .Video:
            let environment = VideoBlockViewController.Environment(courseDataManager: self.environment.dataManager.courseDataManager, interface : self.environment.interface, styles : self.environment.styles)
            let controller = VideoBlockViewController(environment: environment, blockID: blockID, courseID: courseID)
            return controller
        case .Unknown:
            let environment = CourseUnknownBlockViewController.Environment(dataManager : self.environment.dataManager, styles : self.environment.styles)
            let controller = CourseUnknownBlockViewController(blockID: blockID, courseID : courseID, environment : environment)
            return controller
        }
    }
    
    func controllerForBlock(block : CourseBlock, courseID : String) -> UIViewController {
        return controllerForBlockWithID(block.blockID, type: block.displayType, courseID: courseID)
    }
    
    func showFullScreenMessageViewControllerFromViewController(controller : UIViewController, message : String, bottomButtonTitle: String?) {
        let fullScreenViewController = FullScreenMessageViewController(message: message, bottomButtonTitle: bottomButtonTitle)
        controller.presentViewController(fullScreenViewController, animated: true, completion: nil)
    }
    
    func showDiscussionResponsesFromViewController(controller: UIViewController, courseID : String, item : DiscussionPostItem) {
        let environment = DiscussionResponsesViewController.Environment(networkManager: self.environment.networkManager, router: self, styles : self.environment.styles)
        let storyboard = UIStoryboard(name: "DiscussionResponses", bundle: nil)
        let responsesViewController = storyboard.instantiateInitialViewController() as! DiscussionResponsesViewController
        responsesViewController.environment = environment
        responsesViewController.courseID = courseID
        responsesViewController.postItem = item
        controller.navigationController?.pushViewController(responsesViewController, animated: true)
    }
    
    func showDiscussionCommentsFromViewController(controller: UIViewController, courseID : String, item : DiscussionResponseItem, closed : Bool) {
        let environment = DiscussionCommentsViewController.Environment(
            courseDataManager: self.environment.dataManager.courseDataManager,
            router: self, networkManager : self.environment.networkManager)
        let commentsVC = DiscussionCommentsViewController(environment: environment, courseID : courseID, responseItem: item, closed: closed)
        controller.navigationController?.pushViewController(commentsVC, animated: true)
    }
    
    func showDiscussionNewCommentFromController(controller: UIViewController, courseID : String, item: DiscussionItem) {
        let environment = DiscussionNewCommentViewController.Environment(
            courseDataManager: self.environment.dataManager.courseDataManager,
            networkManager: self.environment.networkManager,
            router: self)
        let newCommentViewController = DiscussionNewCommentViewController(environment: environment, courseID : courseID, item: item)
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
        let environment = DiscussionTopicsViewController.Environment(
            config: self.environment.config,
            courseDataManager: self.environment.dataManager.courseDataManager,
            networkManager: self.environment.networkManager,
            router: self,
            styles : self.environment.styles
        )
        let topicsController = DiscussionTopicsViewController(environment: environment, courseID: courseID)
        controller.navigationController?.pushViewController(topicsController, animated: true)
    }

    func showDiscussionNewPostFromController(controller: UIViewController, courseID : String, selectedTopic : DiscussionTopic?) {
        let environment = DiscussionNewPostViewController.Environment(
            courseDataManager : self.environment.dataManager.courseDataManager,
            networkManager: self.environment.networkManager,
            router: self)
        let newPostController = DiscussionNewPostViewController(environment: environment, courseID: courseID, selectedTopic: selectedTopic)
        let navigationController = UINavigationController(rootViewController: newPostController)
        controller.presentViewController(navigationController, animated: true, completion: nil)
    }
    
    func showHandoutsFromController(controller : UIViewController, courseID : String) {
        let environment = CourseHandoutsViewController.Environment(
            dataManager : self.environment.dataManager,
            networkManager: self.environment.networkManager,
            styles: self.environment.styles)
        let handoutsViewController = CourseHandoutsViewController(environment: environment, courseID: courseID)
        controller.navigationController?.pushViewController(handoutsViewController, animated: true)
    }

    func showProfileForUsername(controller: UIViewController? = nil, username : String, editable: Bool = true) {
        let env = UserProfileViewController.Environment(networkManager: environment.networkManager)
        let profileController = UserProfileViewController(username: username, environment: env, editable: editable)
        if let controller = controller {
            controller.navigationController?.pushViewController(profileController, animated: true)
        } else {
            self.showContentStackWithRootController(profileController, animated: true)
        }
    }
}

