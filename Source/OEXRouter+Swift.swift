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

extension CourseBlockType {
    
    var displayType : CourseBlockDisplayType {
        switch self {
        case .Unknown(_): return .Unknown
        case .Course: return .Outline
        case .Chapter: return .Outline
        case .Section: return .Outline
        case .Unit: return .Unit
        case .Video(_): return .Video
        case .HTML: return .HTML
        case .Problem: return .HTML
        }
    }
}
// TODO: remove and add a real stub controller for each class
class XXXTempCourseBlockViewController : UIViewController, CourseBlockViewController {
    let blockID : CourseBlockID

    init(blockID : CourseBlockID) {
        self.blockID = blockID
        super.init(nibName: nil, bundle: nil)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension OEXRouter {
    func showCoursewareForCourseWithID(courseID : String, fromController controller : UIViewController) {
        showContainerForBlockWithID(courseID, type: CourseBlockDisplayType.Outline, parentID: courseID, courseID : courseID, fromController: controller)
    }
    
    func unitControllerForCourseID(courseID : String, blockID : CourseBlockID, initialChildID : CourseBlockID?) -> UIViewController {
        let environment = CourseContentPageViewControllerEnvironment(dataManager: self.environment.dataManager, router: self)
        let contentPageController = CourseContentPageViewController(environment: environment, courseID: courseID, rootID: blockID, initialChildID: initialChildID)
        return contentPageController
    }
    
    func showContainerForBlockWithID(blockID : CourseBlockID, type : CourseBlockDisplayType, parentID : CourseBlockID, courseID : CourseBlockID, fromController controller: UIViewController) {
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
    
    func controllerForBlockWithID(blockID : CourseBlockID, type : CourseBlockDisplayType, courseID : String) -> UIViewController {
        switch type {
            case .Outline:
                let environment = CourseOutlineViewControllerEnvironment(dataManager: self.environment.dataManager, router: self)
                let outlineController = CourseOutlineViewController(environment: environment, courseID: courseID, rootID: blockID)
                return outlineController
        case .Unit:
            return unitControllerForCourseID(courseID, blockID: blockID, initialChildID: nil)
        case .HTML:
            let controller = XXXTempCourseBlockViewController(blockID: blockID)
            controller.view.backgroundColor = UIColor.redColor()
            return controller
        case .Video:
            let controller = XXXTempCourseBlockViewController(blockID: blockID)
            controller.view.backgroundColor = UIColor.greenColor()
            return controller
        case .Unknown:
            let controller = XXXTempCourseBlockViewController(blockID: blockID)
            controller.view.backgroundColor = UIColor.orangeColor()
            return controller
        }
    }
}