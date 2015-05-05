//
//  CourseContentPageViewController.swift
//  edX
//
//  Created by Akiva Leffert on 5/1/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation


class CourseContentPageViewControllerEnvironment : NSObject {
    weak var router : OEXRouter?
    
    init(router : OEXRouter) {
        self.router = router
    }
}

// Container for scrolling horizontally between different screens of course content
// TODO: Styles, full vs video mode
class CourseContentPageViewController : UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, CourseBlockViewController {

    private let environment : CourseContentPageViewControllerEnvironment
    
    private let courseID : CourseBlockID
    private let rootID : CourseBlockID
    private var currentChildID : CourseBlockID
    
    var blockID : CourseBlockID {
        return rootID
    }
    
    private let prevItem : UIBarButtonItem
    private let nextItem : UIBarButtonItem
    
    private var loader : Promise<[CourseBlock]>?
    
    private let courseQuerier : CourseOutlineQuerier
    private var currentMode : CourseOutlineMode = .Full // TODO - load from storage
    
    
    init(environment : CourseContentPageViewControllerEnvironment, courseID : CourseBlockID, rootID : CourseBlockID, initialChildID: CourseBlockID) {
        self.environment = environment
        self.rootID = rootID
        self.currentChildID = initialChildID
        self.courseID = courseID
        
        courseQuerier = CourseOutlineQuerier(courseID: courseID, outline: CourseOutline.freshCourseOutline(courseID))
            
        prevItem = UIBarButtonItem(title: OEXLocalizedString("PREVIOUS", nil), style: .Plain, target: nil, action:nil)
        nextItem = UIBarButtonItem(title: OEXLocalizedString("NEXT", nil), style: UIBarButtonItemStyle.Plain, target: nil, action:nil)
        
        super.init(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
        self.dataSource = self
        self.delegate = self
        
        prevItem.oex_setAction {[weak self] _ in
            self?.moveInDirection(.Reverse)
        }
        
        nextItem.oex_setAction {[weak self] _ in
            self?.moveInDirection(.Forward)
        }
    }

    required init(coder aDecoder: NSCoder) {
        // required by the compiler because UIViewController implements NSCoding,
        // but we don't actually want to serialize these things
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(animated : Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(false, animated: animated)

        loadIfNecessary()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setToolbarHidden(true, animated: animated)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.whiteColor()
        
        prevItem.enabled = false
        nextItem.enabled = false
        
        self.toolbarItems = [
            prevItem,
            UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil),
            nextItem
        ]
    }
    
    private func loadIfNecessary() {
        if loader == nil {
            let action = courseQuerier.childrenOfBlockWithID(rootID, mode: currentMode)
            loader = action
            action.then {[weak self] blocks -> Void in
                for block in blocks {
                    if let owner = self where block.blockID == self?.currentChildID {
                        if let controller = owner.environment.router?.controllerForContentBlockType(block.type.rawValue, courseID:owner.courseID, blockID: block.blockID) {
                            owner.setViewControllers([controller], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
                            owner.validateNextPrevButtons()
                        }
                        else {
                            // TODO handle error
                        }
                        break
                    }
                }
                // TODO show block not found
                return
            }
            
            // TODO handle error
        }
    }
    
    private func validateNextPrevButtons() {
        let children = loader?.value
        let index = children.flatMap {
            $0.firstIndexMatching {node in
                return node.blockID == currentChildID
            }
        }
        if let i = index {
            prevItem.enabled = i > 0
            nextItem.enabled = i + 1 < (children?.count ?? 0)
        }
        else {
            prevItem.enabled = false
            nextItem.enabled = false
        }
    }
    
    // MARK: Paging
    
    private func siblingAtOffset(offset : Int, fromController viewController: UIViewController) -> UIViewController? {
        let blockController = viewController as! CourseBlockViewController
        return loader?.value.flatMap { siblings in
            return siblings.firstIndexMatching {node in
                return node.blockID == blockController.blockID
            }.flatMap {index in
                let newIndex = index + offset
                if newIndex < 0 || newIndex >= siblings.count {
                    return nil
                }
                else {
                    let sibling = siblings[newIndex]
                    let controller = self.environment.router?.controllerForContentBlockType(sibling.type.rawValue, courseID: self.courseID, blockID: sibling.blockID)
                    return controller
                }

            }
        }
    }
    
    private func moveInDirection(direction : UIPageViewControllerNavigationDirection) {
        let offset = direction == .Forward ? 1 : -1
        (viewControllers.first as? UIViewController).flatMap {
            self.siblingAtOffset(offset, fromController: $0)
        }.map { nextController -> Void in
            self.setViewControllers([nextController], direction: direction, animated: true, completion: nil)
            
            if let blockController = nextController as? CourseBlockViewController {
                currentChildID = blockController.blockID
            }
            return
        }
        self.validateNextPrevButtons()
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        return siblingAtOffset(-1, fromController: viewController)
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        return siblingAtOffset(1, fromController: viewController)
    }
    
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [AnyObject], transitionCompleted completed: Bool) {
        if let currentController = pageViewController.viewControllers.first as? CourseBlockViewController {
            currentChildID = currentController.blockID
        }
        self.validateNextPrevButtons()
    }
}