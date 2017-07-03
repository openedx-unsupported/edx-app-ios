//
//  CourseContentPageViewController.swift
//  edX
//
//  Created by Akiva Leffert on 5/1/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation

public protocol CourseContentPageViewControllerDelegate : class {
    func courseContentPageViewController(controller : CourseContentPageViewController, enteredBlockWithID blockID : CourseBlockID, parentID : CourseBlockID)
}

extension CourseBlockDisplayType {
    var isCacheable : Bool {
        switch self {
        case .Video: return false
        case .Unknown, .HTML(_), .Outline, .Unit, .Discussion: return true
        }
    }
}

// Container for scrolling horizontally between different screens of course content
public class CourseContentPageViewController : UIPageViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, CourseBlockViewController, StatusBarOverriding, InterfaceOrientationOverriding {
    
    public typealias Environment = OEXAnalyticsProvider & DataManagerProvider & OEXRouterProvider
    
    private let initialLoadController : LoadStateViewController
    private let environment : Environment
    
    private var initialChildID : CourseBlockID?
    
    public private(set) var blockID : CourseBlockID?
    
    public var courseID : String {
        return courseQuerier.courseID
    }
    
    private var openURLButtonItem : UIBarButtonItem?
    
    fileprivate var contentLoader = BackedStream<ListCursor<CourseOutlineQuerier.GroupItem>>()
    
    private let courseQuerier : CourseOutlineQuerier
    private var courseOutlineMode: CourseOutlineMode
    weak var navigationDelegate : CourseContentPageViewControllerDelegate?
    
    ///Manages the caching of the viewControllers that have been viewed atleast once.
    ///Removes the ViewControllers from memory in case of a memory warning
    private let cacheManager : BlockViewControllerCacheManager
    
    public init(environment : Environment, courseID : CourseBlockID, rootID : CourseBlockID?, initialChildID: CourseBlockID? = nil, forMode mode: CourseOutlineMode) {
        self.environment = environment
        self.blockID = rootID
        self.initialChildID = initialChildID
        
        courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID: courseID)
        initialLoadController = LoadStateViewController()
        
        cacheManager = BlockViewControllerCacheManager()
        courseOutlineMode = mode
        super.init(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        self.setViewControllers([initialLoadController], direction: .forward, animated: false, completion: nil)
        
        self.dataSource = self
        self.delegate = self
        
        addStreamListeners()
    }

    public required init?(coder aDecoder: NSCoder) {
        // required by the compiler because UIViewController implements NSCoding,
        // but we don't actually want to serialize these things
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewWillAppear(_ animated : Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(false, animated: animated)
        courseQuerier.blockWithID(id: blockID).extendLifetimeUntilFirstResult (success:
            { block in
                self.environment.analytics.trackScreen(withName: OEXAnalyticsScreenUnitDetail, courseID: self.courseID, value: block.internalName)
            },
            failure: {
                Logger.logError("ANALYTICS", "Unable to load block: \($0)")
            }
        )

        loadIfNecessary()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setToolbarHidden(true, animated: animated)
        removeObservers()
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        
        
        // This is super hacky. Controls like sliders - that depend on pan gestures were getting intercepted
        // by the page view's scroll view. This seemed like the only solution.
        // Filed http://www.openradar.appspot.com/radar?id=6188034965897216 against Apple to better expose
        // this API.
        // Verified on iOS9 and iOS 8
        if let scrollView = (self.view.subviews.flatMap { return $0 as? UIScrollView }).first {
            scrollView.delaysContentTouches = false
        }
        addObservers()
    }
    
    private func addStreamListeners() {
        contentLoader.listen(self,
            success : {[weak self] cursor -> Void in
                if let owner = self, let controller = owner.controllerForBlock(block: cursor.current.block)
                {
                    owner.setViewControllers([controller], direction: UIPageViewControllerNavigationDirection.forward, animated: false, completion: nil)
                    self?.updateNavigationForEnteredController(controller: controller)
                }
                else {
                    self?.initialLoadController.state = LoadState.failed(error: NSError.oex_courseContentLoadError())
                    self?.updateNavigationBars()
                }
                
                return
            }, failure : {[weak self] error in
             self?.initialLoadController.state = LoadState.failed(error: NSError.oex_courseContentLoadError())
            }
        )
    }
    
    private func addObservers() {
        
        NotificationCenter.default.oex_addObserver(observer: self, name: NOTIFICATION_VIDEO_PLAYER_PREVIOUS) { (notification, observer, removable) in
            observer.moveInDirection(direction: .reverse)
        }
        
        NotificationCenter.default.oex_addObserver(observer: self, name: NOTIFICATION_VIDEO_PLAYER_NEXT) { (_, observer, _) in
            observer.moveInDirection(direction: .forward)
        }
    }
    
    private func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NOTIFICATION_VIDEO_PLAYER_NEXT), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: NOTIFICATION_VIDEO_PLAYER_PREVIOUS), object: nil)
    }
    
    private func loadIfNecessary() {
        if !contentLoader.hasBacking {
            let stream = courseQuerier.spanningCursorForBlockWithID(blockID: blockID, initialChildID: initialChildID, forMode: courseOutlineMode)
            contentLoader.backWithStream(stream.firstSuccess())
        }
    }
    
    // Accessibility elements can be set from child. This was required for only enable VO for Timely App Reviews
    func setAccessibility(elements: [UIView]?, isShowingRating: Bool? = false) {
        // Setting toolbarItems empty because isAccessibiltyElement false was not working for toolbarItems.
        //TODO: Needs to revist this approch and find a way to disable accessibility for toolbarItems
        if isShowingRating ?? false {
            toolbarItems = []
        }
        else {
            updateNavigationBars()
        }
        
        if let elements = elements {
            view.accessibilityElements = elements
        }
        else {
            view.accessibilityElements = [view.subviews]
        }
    }
    
    private func toolbarItemWithGroupItem(item : CourseOutlineQuerier.GroupItem, adjacentGroup : CourseBlock?, direction : DetailToolbarButton.Direction, enabled : Bool) -> UIBarButtonItem {
        let titleText : String
        let moveDirection : UIPageViewControllerNavigationDirection
        let isGroup = adjacentGroup != nil
        
        switch direction {
        case .Next:
            titleText = isGroup ? Strings.nextUnit : Strings.next
            moveDirection = .forward
        case .Prev:
            titleText = isGroup ? Strings.previousUnit : Strings.previous
            moveDirection = .reverse
        }
        
        let destinationText = adjacentGroup?.displayName
        
        let view = DetailToolbarButton(direction: direction, titleText: titleText, destinationText: destinationText) {[weak self] in
            self?.moveInDirection(direction: moveDirection)
        }
        view.sizeToFit()
        
        let barButtonItem =  UIBarButtonItem(customView: view)
        barButtonItem.isEnabled = enabled
        view.button.isEnabled = enabled
        return barButtonItem
    }
    
    private func updateNavigationBars() {
        if let cursor = contentLoader.value {
            let item = cursor.current
            
            // only animate change if we haven't set a title yet, so the initial set happens without
            // animation to make the push transition work right
            let actions : () -> Void = {
                self.navigationItem.title = item.block.displayName
            }
            if let navigationBar = navigationController?.navigationBar, let _ = navigationItem.title {
                let animated = navigationItem.title != nil
                UIView.transition(with: navigationBar,
                    duration: 0.3 * (animated ? 1.0 : 0.0), options: UIViewAnimationOptions.transitionCrossDissolve,
                    animations: actions, completion: nil)
            }
            else {
                actions()
            }
            
            let prevItem = toolbarItemWithGroupItem(item: item, adjacentGroup: item.prevGroup, direction: .Prev, enabled: cursor.hasPrev)
            let nextItem = toolbarItemWithGroupItem(item: item, adjacentGroup: item.nextGroup, direction: .Next, enabled: cursor.hasNext)
            
            self.setToolbarItems(
                [
                    prevItem,
                    UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
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
        case .forward:
            item = contentLoader.value?.peekNext()
        case .reverse:
            item = contentLoader.value?.peekPrev()
        }
        return item.flatMap {
            controllerForBlock(block: $0.block)
        }
    }
    
    private func updateNavigationForEnteredController(controller : UIViewController?) {
        
        if let blockController = controller as? CourseBlockViewController,
            let cursor = contentLoader.value
        {
            cursor.updateCurrentToItemMatching {
                blockController.blockID == $0.block.blockID
            }
            environment.analytics.trackViewedComponentForCourse(withID: courseID, blockID: cursor.current.block.blockID, minifiedBlockID: cursor.current.block.minifiedBlockID ?? "")
            self.navigationDelegate?.courseContentPageViewController(controller: self, enteredBlockWithID: cursor.current.block.blockID, parentID: cursor.current.parent)
        }
        self.updateNavigationBars()
    }
    
    fileprivate func moveInDirection(direction : UIPageViewControllerNavigationDirection) {
        if let currentController = viewControllers?.first,
            let nextController = self.siblingWithDirection(direction: direction, fromController: currentController)
        {
            self.setViewControllers([nextController], direction: direction, animated: true, completion: nil)
            self.updateNavigationForEnteredController(controller: nextController)
        }
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        return siblingWithDirection(direction: .reverse, fromController: viewController)
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        return siblingWithDirection(direction: .forward, fromController: viewController)
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        self.updateNavigationForEnteredController(controller: pageViewController.viewControllers?.first)
    }
    
    func controllerForBlock(block : CourseBlock) -> UIViewController? {
        let blockViewController : UIViewController?
        
        if let cachedViewController = self.cacheManager.getCachedViewControllerForBlockID(blockID: block.blockID) {
            blockViewController = cachedViewController
        }
        else {
            // Instantiate a new VC from the router if not found in cache already
            if let viewController = self.environment.router?.controllerForBlock(block: block, courseID: courseQuerier.courseID) {
                if block.displayType.isCacheable {
                    cacheManager.addToCache(viewController: viewController, blockID: block.blockID)
                }
                blockViewController = viewController
            }
            else {
                blockViewController = UIViewController()
                assert(false, "Couldn't instantiate viewController for Block \(block)")
            }

        }
        
        if let viewController = blockViewController {
            preloadAdjacentViewControllersFromViewController(controller: viewController)
            return viewController
        }
        else {
            assert(false, "Couldn't instantiate viewController for Block \(block)")
            return nil
        }
        
        
    }
    

    override public var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle(barStyle : self.navigationController?.navigationBar.barStyle)
    }
    
    override public var childViewControllerForStatusBarStyle: UIViewController? {
        if let controller = viewControllers?.last as? StatusBarOverriding as? UIViewController {
            return controller
        }
        else {
            return super.childViewControllerForStatusBarStyle
        }
    }
    
    override public var childViewControllerForStatusBarHidden: UIViewController? {
        if let controller = viewControllers?.last as? StatusBarOverriding as? UIViewController {
            return controller
        }
        else {
            return super.childViewControllerForStatusBarHidden
        }
        
    }
    
    override public var shouldAutorotate: Bool {
        return true
    }
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return [.portrait , .landscapeLeft , .landscapeRight]
    }
    
    private func preloadBlock(block : CourseBlock) {
        guard !cacheManager.cacheHitForBlockID(blockID: block.blockID) else {
            return
        }
        guard block.displayType.isCacheable else {
            return
        }
        guard let controller = self.environment.router?.controllerForBlock(block: block, courseID: courseQuerier.courseID) else {
            return
        }
        cacheManager.addToCache(viewController: controller, blockID: block.blockID)
        
        if let preloadable = controller as? PreloadableBlockController {
            preloadable.preloadData()
        }
    }

    private func preloadAdjacentViewControllersFromViewController(controller : UIViewController) {
        if let block = contentLoader.value?.peekNext()?.block {
            preloadBlock(block: block)
        }
        
        if let block = contentLoader.value?.peekPrev()?.block {
            preloadBlock(block: block)
        }
    }
}

// MARK: Testing
extension CourseContentPageViewController {
    public func t_blockIDForCurrentViewController() -> OEXStream<CourseBlockID> {
        return contentLoader.flatMap {blocks in
            let controller = (self.viewControllers?.first as? CourseBlockViewController)
            let blockID = controller?.blockID
            let result = blockID.toResult()
            return result
        }
    }
    
    public var t_prevButtonEnabled : Bool {
        return self.toolbarItems![0].isEnabled
    }
    
    public var t_nextButtonEnabled : Bool {
        return self.toolbarItems![2].isEnabled
    }
    
    public func t_goForward() {
        moveInDirection(direction: .forward)
    }
    
    public func t_goBackward() {
        moveInDirection(direction: .reverse)
    }
}
