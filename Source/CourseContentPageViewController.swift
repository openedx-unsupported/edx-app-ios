//
//  CourseContentPageViewController.swift
//  edX
//
//  Created by Akiva Leffert on 5/1/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

// Container for scrolling horizontally between different screens of course content
// TODO: Styles, full vs video mode
public class CourseContentPageViewController : UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, CourseBlockViewController {
    
    public class Environment : NSObject {
        weak var router : OEXRouter?
        let dataManager : DataManager
        
        public init(dataManager : DataManager, router : OEXRouter) {
            self.dataManager = dataManager
            self.router = router
        }
    }

    private let environment : Environment
    
    private var currentChildID : CourseBlockID?
    
    public private(set) var blockID : CourseBlockID
    
    public var courseID : String {
        return courseQuerier.courseID
    }
    
    private let prevItem : UIBarButtonItem
    private let nextItem : UIBarButtonItem
    
    private var contentLoader : Promise<[CourseBlock]>?
    private var setupFinished : Promise<Void>?
    
    private let courseQuerier : CourseOutlineQuerier
    private var currentMode : CourseOutlineMode = .Full // TODO - load from storage
    
    
    public init(environment : Environment, courseID : CourseBlockID, rootID : CourseBlockID, initialChildID: CourseBlockID? = nil) {
        self.environment = environment
        self.blockID = rootID
        self.currentChildID = initialChildID
        
        courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID)
            
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

    public required init(coder aDecoder: NSCoder) {
        // required by the compiler because UIViewController implements NSCoding,
        // but we don't actually want to serialize these things
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewWillAppear(animated : Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(false, animated: animated)

        loadIfNecessary()
    }
    
    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setToolbarHidden(true, animated: animated)
    }
    
    public override func viewDidLoad() {
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
        if contentLoader == nil {
            let action = courseQuerier.childrenOfBlockWithID(blockID, mode: currentMode)
            contentLoader = action
            updateNavigation()
                
            setupFinished = action.then {[weak self] blocks -> Void in
                // Start by trying to show the currently set child
                // Handle the case where the given child id is invalid
                // By verifiying it's in the children
                let blockFound = blocks.firstIndexMatching {
                    $0.blockID == self?.currentChildID
                } != nil
                
                self?.currentChildID = blockFound ? self?.currentChildID : blocks.first?.blockID
                
                for block in blocks {
                    if let owner = self where block.blockID == self?.currentChildID {
                        if let controller = owner.environment.router?.controllerForBlockWithID(block.blockID, type: block.type.displayType, courseID: owner.courseQuerier.courseID) {
                            owner.setViewControllers([controller], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
                        }
                        else {
                            // TODO handle error
                        }
                        break
                    }
                }
                // TODO show block not found
                
                self?.updateNavigation()
                return
            }
        }
    }
    
    private func titleOfCurrentChild() -> String? {
        if let children = contentLoader?.value, child = children.firstObjectMatching({$0.blockID == currentChildID}) {
            return child.name
        }
        return nil
    }
    
    private func updateNavigation() {
        self.navigationItem.title = titleOfCurrentChild()
        
        let children = contentLoader?.value
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
        return contentLoader?.value.flatMap { siblings in
            return siblings.firstIndexMatching {node in
                return node.blockID == blockController.blockID
            }.flatMap {index in
                let newIndex = index + offset
                if newIndex < 0 || newIndex >= siblings.count {
                    return nil
                }
                else {
                    let sibling = siblings[newIndex]
                    let controller = self.environment.router?.controllerForBlockWithID(sibling.blockID, type: sibling.type.displayType, courseID: courseQuerier.courseID)
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
        self.updateNavigation()
    }
    
    public func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        return siblingAtOffset(-1, fromController: viewController)
    }
    
    public func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        return siblingAtOffset(1, fromController: viewController)
    }
    
    public func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [AnyObject], transitionCompleted completed: Bool) {
        if let currentController = pageViewController.viewControllers.first as? CourseBlockViewController {
            currentChildID = currentController.blockID
        }
        self.updateNavigation()
    }
}

// MARK: Testing
extension CourseContentPageViewController {
    public func t_blockIDForCurrentViewController() -> Promise<CourseBlockID?> {
        return setupFinished!.then {_ -> CourseBlockID? in
            println("\(self.viewControllers)")
            return (self.viewControllers.first as? CourseBlockViewController)?.blockID
        }
    }
    
    public var t_prevButtonEnabled : Bool {
        return self.prevItem.enabled
    }
    
    public var t_nextButtonEnabled : Bool {
        return self.nextItem.enabled
    }
    
    public func t_goForward() {
        moveInDirection(.Forward)
    }
    
    public func t_goBackward() {
        moveInDirection(.Reverse)
    }
}