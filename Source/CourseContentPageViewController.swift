//
//  CourseContentPageViewController.swift
//  edX
//
//  Created by Akiva Leffert on 5/1/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

public protocol CourseContentPageViewControllerDelegate : class {
    func courseContentPageViewController(controller : CourseContentPageViewController, enteredItemInGroup blockID : CourseBlockID)
}

// Container for scrolling horizontally between different screens of course content
// TODO: Styles, full vs video mode
public class CourseContentPageViewController : UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, CourseBlockViewController, CourseOutlineModeControllerDelegate, ContainedNavigationController {
    
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

    private let initialLoadController : LoadStateViewController
    private let environment : Environment
    
    private var initialChildID : CourseBlockID?
    
    public private(set) var blockID : CourseBlockID?
    
    public var courseID : String {
        return courseQuerier.courseID
    }
    
    private var openURLButtonItem : UIBarButtonItem?
    
    private var contentLoader = BackedStream<ListCursor<CourseOutlineQuerier.GroupItem>>()
    
    private let courseQuerier : CourseOutlineQuerier
    private let modeController : CourseOutlineModeController
    
    private var webController : OpenOnWebController!
    weak var navigationDelegate : CourseContentPageViewControllerDelegate?
    
    ///Manages the caching of the viewControllers that have been viewed atleast once.
    ///Removes the ViewControllers from memory in case of a memory warning
    private let cacheManager : BlockViewControllerCacheManager
    
    public init(environment : Environment, courseID : CourseBlockID, rootID : CourseBlockID?, initialChildID: CourseBlockID? = nil) {
        self.environment = environment
        self.blockID = rootID
        self.initialChildID = initialChildID
        
        courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID)
        
        modeController = environment.dataManager.courseDataManager.freshOutlineModeController()
        initialLoadController = LoadStateViewController(styles: environment.styles)
        
        cacheManager = BlockViewControllerCacheManager()
        
        super.init(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
        self.setViewControllers([initialLoadController], direction: .Forward, animated: false, completion: nil)
        
        modeController.delegate = self
        
        self.dataSource = self
        self.delegate = self
        
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
    }
    
    private func addStreamListeners() {
        contentLoader.listen(self,
            success : {[weak self] cursor -> Void in
                if let owner = self,
                     controller = owner.controllerForBlock(cursor.current.block)
                {
                    owner.setViewControllers([controller], direction: UIPageViewControllerNavigationDirection.Forward, animated: false, completion: nil)
                }
                else {
                    self?.initialLoadController.state = LoadState.failed(error: NSError.oex_courseContentLoadError())
                }
                
                self?.updateNavigationBars()
                return
            }, failure : {[weak self] error in
             self?.initialLoadController.state = LoadState.failed(error: NSError.oex_courseContentLoadError())
            }
        )
    }
    

    
    private func loadIfNecessary() {
        if !contentLoader.hasBacking {
            let stream = courseQuerier.spanningCursorForBlockWithID(blockID, initialChildID: initialChildID, forMode: modeController.currentMode)
            contentLoader.backWithStream(stream.firstSuccess())
        }
    }
    
    private func toolbarItemWithGroupItem(item : CourseOutlineQuerier.GroupItem, adjacentGroup : CourseBlock?, direction : DetailToolbarButton.Direction, enabled : Bool) -> UIBarButtonItem {
        let moveDirection : UIPageViewControllerNavigationDirection
        let title : String
        
        switch direction {
        case .Next:
            title = OEXLocalizedString("NEXT_UNIT", nil)
            moveDirection = .Forward
        case .Prev:
            title = OEXLocalizedString("PREVIOUS_UNIT", nil)
            moveDirection = .Reverse
        }
        
        if let group = adjacentGroup {
            let view = DetailToolbarButton(direction: direction, titleText: title, destinationText: group.name) {[weak self] in
                self?.moveInDirection(moveDirection)
            }
            view.sizeToFit()
            return UIBarButtonItem(customView: view)
        }
        else {
            let buttonItem = UIBarButtonItem(title: title, style: .Plain, target: nil, action:nil)
            buttonItem.enabled = enabled
            buttonItem.oex_setAction {[weak self] _ in
                self?.moveInDirection(moveDirection)
            }
            return buttonItem
        }
    }
    
    private func updateNavigationBars() {
        if let cursor = contentLoader.value {
            let item = cursor.current
            
            // only animate chnage if we haven't set a title yet, so the initial set happens without
            // animation to make the push transition work right
            if let navigationBar = navigationController?.navigationBar where navigationItem.title != nil {
                UIView.transitionWithView(navigationBar,
                    duration: 0.3, options: UIViewAnimationOptions.TransitionCrossDissolve,
                    animations: {
                        self.navigationItem.title = item.block.name ?? ""
                        self.webController.URL = item.block.webURL
                    }, completion: nil)
            }
            
            let prevItem = toolbarItemWithGroupItem(item, adjacentGroup: item.prevGroup, direction: .Prev, enabled: cursor.hasPrev)
            let nextItem = toolbarItemWithGroupItem(item, adjacentGroup: item.nextGroup, direction: .Next, enabled: cursor.hasNext)
            
            self.setToolbarItems(
                [
                    prevItem,
                    UIBarButtonItem(barButtonSystemItem: .FlexibleSpace, target: nil, action: nil),
                    nextItem
                ], animated : true)
        }
        else {
            self.toolbarItems = []
        }
    }
    
    // MARK: Paging
    
    private func siblingWithDirection(direction : UIPageViewControllerNavigationDirection, fromController viewController: UIViewController) -> UIViewController? {
        let item : CourseOutlineQuerier.GroupItem?
        switch direction {
        case .Forward:
            item = contentLoader.value?.peekNext()
        case .Reverse:
            item = contentLoader.value?.peekPrev()
        }
        return item.flatMap {
            controllerForBlock($0.block)
        }
    }
    
    private func updateNavigationForEnteredController(controller : UIViewController?) {
        
        if let blockController = controller as? CourseBlockViewController,
            cursor = contentLoader.value
        {
            cursor.updateCurrentToItemMatching {
                blockController.blockID == $0.block.blockID
            }
            self.navigationDelegate?.courseContentPageViewController(self, enteredItemInGroup: cursor.current.parent)
        }
        self.updateNavigationBars()
    }
    
    private func moveInDirection(direction : UIPageViewControllerNavigationDirection) {
        (viewControllers.first as? UIViewController).flatMap {controller -> UIViewController? in
            self.siblingWithDirection(direction, fromController: controller)
        }.map { nextController -> Void in
            self.setViewControllers([nextController], direction: direction, animated: true, completion: nil)
            self.updateNavigationForEnteredController(nextController)
            return
        }
    }
    
    public func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        return siblingWithDirection(.Reverse, fromController: viewController)
    }
    
    public func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        return siblingWithDirection(.Forward, fromController: viewController)
    }
    
    public func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [AnyObject], transitionCompleted completed: Bool) {
        self.updateNavigationForEnteredController(pageViewController.viewControllers.first as? UIViewController)
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
    
    func controllerForBlock(block : CourseBlock) -> UIViewController? {
        let blockViewController : UIViewController?
        
        if let cachedViewController = self.cacheManager.getCachedViewControllerForBlockID(block.blockID) {
            blockViewController = cachedViewController
        }
        else {
            // Instantiate a new VC from the router if not found in cache already
            if let viewController = self.environment.router?.controllerForBlock(block, courseID: courseQuerier.courseID) {
                cacheManager.addToCache(viewController, blockID: block.blockID)
                blockViewController = viewController
            }
            else {
                blockViewController = UIViewController()
                assert(false, "Couldn't instantiate viewController for Block \(block)")
            }

        }
        
        if let viewController = blockViewController {
            preloadAdjacentViewControllersFromViewController(viewController)
            return viewController
        }
        else {
            assert(false, "Couldn't instantiate viewController for Block \(block)")
            return nil
        }
        
        
    }
    

    override public func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle(barStyle : self.navigationController?.navigationBar.barStyle)
    }
    
    override public func childViewControllerForStatusBarStyle() -> UIViewController? {
        if let controller = viewControllers.last as? ContainedNavigationController as? UIViewController {
            return controller
        }
        else {
            return super.childViewControllerForStatusBarStyle()
        }
    }
    
    override public func childViewControllerForStatusBarHidden() -> UIViewController? {
        if let controller = viewControllers.last as? ContainedNavigationController as? UIViewController {
            return controller
        }
        else {
            return super.childViewControllerForStatusBarHidden()
        }
        
    }
    
    private func preloadBlock(block : CourseBlock) {
        if cacheManager.cacheHitForBlockID(block.blockID) {
            return
        }
        if let controller = self.environment.router?.controllerForBlock(block, courseID: courseQuerier.courseID) {
            if let preloadable = controller as? PreloadableBlockController {
                preloadable.preloadData()
            }
            cacheManager.addToCache(controller, blockID: block.blockID)
        }
    }

    private func preloadAdjacentViewControllersFromViewController(controller : UIViewController) {
        if let block = contentLoader.value?.peekNext()?.block {
            preloadBlock(block)
        }
        
        if let block = contentLoader.value?.peekPrev()?.block {
            preloadBlock(block)
        }
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
        return (self.toolbarItems![0] as! UIBarButtonItem).enabled
    }
    
    public var t_nextButtonEnabled : Bool {
        return (self.toolbarItems![2] as! UIBarButtonItem).enabled
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