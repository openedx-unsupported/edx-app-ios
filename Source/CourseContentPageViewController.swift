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
public class CourseContentPageViewController : UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, CourseBlockViewController, CourseOutlineModeControllerDelegate {
    
    public class Environment : NSObject {
        let dataManager : DataManager
        weak var router : OEXRouter?
        var styles : OEXStyles?
        
        public init(dataManager : DataManager, router : OEXRouter, styles : OEXStyles?) {
            self.dataManager = dataManager
            self.router = router
            self.styles = styles
        }
    }

    private let environment : Environment
    
    private var currentChildID : CourseBlockID?
    
    public private(set) var blockID : CourseBlockID?
    
    public var courseID : String {
        return courseQuerier.courseID
    }
    
    private let prevItem : UIBarButtonItem
    private let nextItem : UIBarButtonItem
    
    private var openURLButtonItem : UIBarButtonItem?
    
    private var contentLoader = BackedStream<BlockGroup>()
    
    private let courseQuerier : CourseOutlineQuerier
    private let modeController : CourseOutlineModeController
    
    private var webController : OpenOnWebController!
    
    public init(environment : Environment, courseID : CourseBlockID, rootID : CourseBlockID?, initialChildID: CourseBlockID? = nil) {
        self.environment = environment
        self.blockID = rootID
        self.currentChildID = initialChildID
        
        courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID)
            
        prevItem = UIBarButtonItem(title: OEXLocalizedString("PREVIOUS", nil), style: .Plain, target: nil, action:nil)
        nextItem = UIBarButtonItem(title: OEXLocalizedString("NEXT", nil), style: UIBarButtonItemStyle.Plain, target: nil, action:nil)
        
        modeController = environment.dataManager.courseDataManager.freshOutlineModeController()
        
        super.init(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
        
        modeController.delegate = self
        
        self.dataSource = self
        self.delegate = self
        
        
        
        prevItem.oex_setAction {[weak self] _ in
            self?.moveInDirection(.Reverse)
        }
        
        nextItem.oex_setAction {[weak self] _ in
            self?.moveInDirection(.Forward)
        }
        
        webController = OpenOnWebController(inViewController: self)
        navigationItem.rightBarButtonItems = [webController.barButtonItem,modeController.barItem]
        
        addStreamListeners()
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
        
        view.backgroundColor = self.environment.styles?.standardBackgroundColor()
        
        prevItem.enabled = false
        nextItem.enabled = false
        
        self.toolbarItems = [
            prevItem,
            UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil),
            nextItem
        ]
        
    }
    
    private func addStreamListeners() {
        contentLoader.listen(self, success : {[weak self] group -> Void in
            let blocks = group.children
            // Start by trying to show the currently set child
            // Handle the case where the given child id is invalid
            // By verifiying it's in the children
            let blockFound = blocks.firstIndexMatching {
                $0.blockID == self?.currentChildID
                } != nil
            
            self?.currentChildID = blockFound ? self?.currentChildID : blocks.first?.blockID
            
            for block in blocks {
                if let owner = self where block.blockID == self?.currentChildID {
                    if let controller = owner.environment.router?.controllerForBlock(block, courseID: owner.courseQuerier.courseID) {
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
            }, failure : {error in
                
        })
    }
    
    private func loadIfNecessary() {
        if !contentLoader.hasBacking {
            contentLoader.backWithStream(courseQuerier.childrenOfBlockWithID(blockID, forMode: modeController.currentMode).firstSuccess())
        }
    }
    
    private func titleOfCurrentChild() -> String? {
        if let children = contentLoader.value?.children, child = children.firstObjectMatching({$0.blockID == currentChildID}) {
            return child.name
        }
        return nil
    }
    
    private func updateNavigation() {
        self.navigationItem.title = titleOfCurrentChild()
        
        let children = contentLoader.value?.children
        let index = children.flatMap {
            $0.firstIndexMatching {node in
                return node.blockID == currentChildID
            }
        }
        if let i = index {
        
            webController.URL = children?[i].webURL
            prevItem.enabled = i > 0
            nextItem.enabled = i + 1 < (children?.count ?? 0)
        }
        else {
            webController.URL = nil
            prevItem.enabled = false
            nextItem.enabled = false
        }
    }
    
    // MARK: Paging
    
    private func siblingAtOffset(offset : Int, fromController viewController: UIViewController) -> UIViewController? {
        let blockController = viewController as! CourseBlockViewController
        let blocks = contentLoader.value?.children
        return blocks.flatMap { siblings in
            return siblings.firstIndexMatching {node in
                return node.blockID == blockController.blockID
            }.flatMap {index in
                let newIndex = index + offset
                if newIndex < 0 || newIndex >= siblings.count {
                    return nil
                }
                else {
                    let sibling = siblings[newIndex]
                    let controller = self.environment.router?.controllerForBlock(sibling, courseID: courseQuerier.courseID)
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
    
    // MARK: Course Outline Mode
    
    public func courseOutlineModeChanged(courseMode: CourseOutlineMode) {
        // If we change mode we want to pop the screen since it may no longer make sense.
        // It's easy if we're at the top of the controller stack, but we need to be careful if we're not
        if self.navigationController?.topViewController == self {
            self.navigationController?.popViewControllerAnimated(true)
        }
        else {
            self.navigationController?.viewControllers = self.navigationController?.viewControllers.filter {
                return ($0 as! UIViewController) != self
            }
        }
    }
    
    public func viewControllerForCourseOutlineModeChange() -> UIViewController {
        return self
    }
}

// MARK: Testing
extension CourseContentPageViewController {
    public func t_blockIDForCurrentViewController() -> Stream<CourseBlockID> {
        return contentLoader.flatMap {blocks in
            let controller = (self.viewControllers.first as? CourseBlockViewController)
            let blockID = controller?.blockID
            let result = blockID.toResult()
            return result
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
    
    public var t_isRightBarButtonEnabled : Bool {
        return self.webController.barButtonItem.enabled
    }
}