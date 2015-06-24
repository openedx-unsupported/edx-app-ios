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

enum CourseBlockDisplayType {
    case Unknown
    case Outline
    case Unit
    case Video
    case HTML
}

extension CourseBlock {
    
    var displayType : CourseBlockDisplayType {
        switch self.type {
        case .Unknown(_), .HTML, .Problem: return isResponsive ? .HTML : .Unknown
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
    
    func unitControllerForCourseID(courseID : String, blockID : CourseBlockID?, initialChildID : CourseBlockID?) -> UIViewController {
        let environment = CourseContentPageViewController.Environment(dataManager: self.environment.dataManager, router: self, styles : self.environment.styles)
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
            controller.navigationController?.pushViewController(pageController, animated: true)
        }
    }
    
    private func controllerForBlockWithID(blockID : CourseBlockID?, type : CourseBlockDisplayType, courseID : String) -> UIViewController {
        switch type {
            case .Outline:
                let environment = CourseOutlineViewController.Environment(dataManager: self.environment.dataManager, reachability : InternetReachability(), router: self, styles : self.environment.styles, networkManager : self.environment.networkManager)
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
    
    func showFullScreenMessageViewControllerFromViewController(controller : UIViewController, message : String?, bottomButtonTitle: String?) {
        let fullScreenViewController = FullScreenMessageViewController(message: message, bottomButtonTitle: bottomButtonTitle)
        controller.presentViewController(fullScreenViewController, animated: true, completion: nil)
    }
    
    func showDiscussionResponsesFromViewController(controller: UIViewController, item : DiscussionPostItem) {
        let environment = DiscussionResponsesViewControllerEnvironment(router: self, postItem: item)
        let storyboard = UIStoryboard(name: "DiscussionResponses", bundle: nil)
        let responsesViewController : DiscussionResponsesViewController = storyboard.instantiateInitialViewController() as! DiscussionResponsesViewController
        responsesViewController.environment = environment
        controller.navigationController!.pushViewController(responsesViewController, animated: true)
    }
    
    func showDiscussionCommentsFromViewController(controller: UIViewController, item : DiscussionResponseItem) {
        let environment = DiscussionCommentsViewControllerEnvironment(router: self, responseItem: item)
        let commentsVC = DiscussionCommentsViewController(env: environment)
        controller.navigationController!.pushViewController(commentsVC, animated: true)
    }
    
    func showDiscussionNewCommentFromController(controller: UIViewController, isResponse: Bool, item: DiscussionItem) {
        let environment = DiscussionNewCommentViewControllerEnvironment(router: self, item: item)
        let newCommentVC = DiscussionNewCommentViewController(env: environment, isResponse: isResponse)
        if !isResponse {
            newCommentVC.delegate​ = controller as! DiscussionCommentsViewController
        }
        controller.navigationController!.pushViewController(newCommentVC, animated: true)
    }
    
}