//
//  CourseOutlineViewController.swift
//  edX
//
//  Created by Akiva Leffert on 4/30/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import UIKit


public enum CourseOutlineMode {
    case full
    case video
}

public class CourseOutlineViewController :
    OfflineSupportViewController,
    CourseBlockViewController,
    CourseOutlineTableControllerDelegate,
    CourseContentPageViewControllerDelegate,
    CourseLastAccessedControllerDelegate,
    PullRefreshControllerDelegate,
    LoadStateViewReloadSupport,
    InterfaceOrientationOverriding
{
    public typealias Environment = OEXAnalyticsProvider & DataManagerProvider & OEXInterfaceProvider & NetworkManagerProvider & ReachabilityProvider & OEXRouterProvider & OEXConfigProvider & OEXStylesProvider
    
    
    private var rootID : CourseBlockID?
    private var environment : Environment
    
    private let courseQuerier : CourseOutlineQuerier
    fileprivate let tableController : CourseOutlineTableController
    
    private let blockIDStream = BackedStream<CourseBlockID?>()
    private let headersLoader = BackedStream<CourseOutlineQuerier.BlockGroup>()
    fileprivate let rowsLoader = BackedStream<[CourseOutlineQuerier.BlockGroup]>()
    
    private let loadController : LoadStateViewController
    private let insetsController : ContentInsetsController
    private var lastAccessedController : CourseLastAccessedController
    private(set) var courseOutlineMode: CourseOutlineMode
    
    /// Strictly a test variable used as a trigger flag. Not to be used out of the test scope
    fileprivate var t_hasTriggeredSetLastAccessed = false
    
    public var blockID : CourseBlockID? {
        return blockIDStream.value ?? nil
    }
    
    public var courseID : String {
        return courseQuerier.courseID
    }
    
    public init(environment: Environment, courseID : String, rootID : CourseBlockID?, forMode mode: CourseOutlineMode?) {
        self.rootID = rootID
        self.environment = environment
        courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID: courseID)
        
        loadController = LoadStateViewController()
        insetsController = ContentInsetsController()
        courseOutlineMode = mode ?? .full
        tableController = CourseOutlineTableController(environment: self.environment, courseID: courseID, forMode: courseOutlineMode)
        lastAccessedController = CourseLastAccessedController(blockID: rootID , dataManager: environment.dataManager, networkManager: environment.networkManager, courseQuerier: courseQuerier, forMode: courseOutlineMode)
        
        super.init(env: environment, shouldShowOfflineSnackBar: false)
        
        lastAccessedController.delegate = self
        
        addChildViewController(tableController)
        tableController.didMove(toParentViewController: self)
        tableController.delegate = self
    }
    
    
    public required init?(coder aDecoder: NSCoder) {
        // required by the compiler because UIViewController implements NSCoding,
        // but we don't actually want to serialize these things
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        view.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        view.addSubview(tableController.view)
        
        loadController.setupInController(controller: self, contentView:tableController.view)
        tableController.refreshController.setupInScrollView(scrollView: tableController.tableView)
        tableController.refreshController.delegate = self
        
        insetsController.setupInController(owner: self, scrollView : self.tableController.tableView)
        insetsController.addSource(source: tableController.refreshController)
        self.view.setNeedsUpdateConstraints()
        addListeners()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lastAccessedController.loadLastAccessed(forMode: courseOutlineMode)
        lastAccessedController.saveLastAccessed()
        loadStreams()
        
        if courseOutlineMode == .video {
            // We are doing calculations to show downloading progress on video tab, For this purpose we are observing notifications.
            tableController.courseVideosHeaderView?.addObservers()
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if courseOutlineMode == .video {
            // As calculations are made to show progress on view. So when any other view apear we stop observing and making calculations for better performance.
            tableController.courseVideosHeaderView?.removeObservers()
        }
    }
    
    override public var shouldAutorotate: Bool {
        return true
    }
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    override public func updateViewConstraints() {
        loadController.insets = UIEdgeInsets(top: self.topLayoutGuide.length, left: 0, bottom: self.bottomLayoutGuide.length, right : 0)
        
        tableController.view.snp_updateConstraints {make in
            make.edges.equalTo(self.view)
        }
        super.updateViewConstraints()
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.insetsController.updateInsets()
    }
    
    override func reloadViewData() {
        reload()
    }
    
    private func setupNavigationItem(block : CourseBlock) {
        navigationItem.title = (courseOutlineMode == .video && rootID == nil) ? Strings.Dashboard.courseVideos : block.displayName
    }
    
    private func loadStreams() {
        loadController.state = .Initial
        let stream = joinStreams(courseQuerier.rootID, courseQuerier.blockWithID(id: blockID))
        stream.extendLifetimeUntilFirstResult (success :
            { [weak self] (rootID, block) in
                if self?.blockID == rootID || self?.blockID == nil {
                    if self?.courseOutlineMode == .full {
                        self?.environment.analytics.trackScreen(withName: OEXAnalyticsScreenCourseOutline, courseID: self?.courseID, value: nil)
                    }
                    else {
                        self?.environment.analytics.trackScreen(withName: AnalyticsScreenName.CourseVideos.rawValue, courseID: self?.courseID, value: nil)
                    }
                }
                else {
                    self?.environment.analytics.trackScreen(withName: OEXAnalyticsScreenSectionOutline, courseID: self?.courseID, value: block.internalName)
                    self?.tableController.hideTableHeaderView()
                }
            },
                                               failure: {
                                                Logger.logError("ANALYTICS", "Unable to load block: \($0)")
        }
        )
        reload()
    }
    
    private func reload() {
        self.blockIDStream.backWithStream(OEXStream(value : self.blockID))
    }
    
    private func emptyState() -> LoadState {
        return LoadState.empty(icon: .UnknownError, message : (courseOutlineMode == .video) ? Strings.courseVideoUnavailable : Strings.coursewareUnavailable)
    }
    
    private func showErrorIfNecessary(error : NSError) {
        if self.loadController.state.isInitial {
            self.loadController.state = LoadState.failed(error: error)
        }
    }
    
    private func addListeners() {
        headersLoader.backWithStream(blockIDStream.transform {[weak self] blockID in
            if let owner = self {
                return owner.courseQuerier.childrenOfBlockWithID(blockID: blockID, forMode: owner.courseOutlineMode)
            }
            else {
                return OEXStream<CourseOutlineQuerier.BlockGroup>(error: NSError.oex_courseContentLoadError())
            }}
        )
        rowsLoader.backWithStream(headersLoader.transform {[weak self] headers in
            if let owner = self {
                let children = headers.children.map {header in
                    return owner.courseQuerier.childrenOfBlockWithID(blockID: header.blockID, forMode: owner.courseOutlineMode)
                }
                return joinStreams(children)
            }
            else {
                return OEXStream(error: NSError.oex_courseContentLoadError())
            }}
        )
        
        self.blockIDStream.backWithStream(OEXStream(value: rootID))
        
        headersLoader.listen(self,
                             success: {[weak self] headers in
                                self?.setupNavigationItem(block: headers.block)
            },
                             failure: {[weak self] error in
                                self?.showErrorIfNecessary(error: error)
            }
        )
        
        rowsLoader.listen(self,
                          success : {[weak self] groups in
                            if let owner = self {
                                owner.tableController.groups = groups
                                owner.tableController.tableView.reloadData()
                                owner.loadController.state = groups.count == 0 ? owner.emptyState() : .Loaded
                            }
            },
                          failure : {[weak self] error in
                            self?.showErrorIfNecessary(error: error)
            },
                          finally: {[weak self] in
                            if let active = self?.rowsLoader.active, !active {
                                self?.tableController.refreshController.endRefreshing()
                            }
            }
        )
    }
    
    private func isDownloadSettingsValid() -> Bool {
        return environment.dataManager.interface?.isDownloadSettingsValid() ?? false
    }
    
    // MARK: Outline Table Delegate
    
    func outlineTableControllerChoseShowDownloads(controller: CourseOutlineTableController) {
        environment.router?.showDownloads(from: self)
    }
    
    func outlineTableController(controller: CourseOutlineTableController, choseDownloadVideos videos: [OEXHelperVideoDownload], rootedAtBlock block:CourseBlock) {
        if isDownloadSettingsValid() {
            environment.dataManager.interface?.downloadVideos(videos)
            
            let courseID = self.courseID
            let analytics = environment.analytics
            
            courseQuerier.parentOfBlockWithID(blockID: block.blockID).listenOnce(self, success:
                { parentID in
                    analytics.trackSubSectionBulkVideoDownload(parentID, subsection: block.blockID, courseID: courseID, videoCount: videos.count)
            }, failure: {error in
                Logger.logError("ANALYTICS", "Unable to find parent of block: \(block). Error: \(error.localizedDescription)")
            })
        }
        else {
            showOverlay(withMessage: Strings.noWifiMessage)
        }
    }
    
    func outlineTableController(controller: CourseOutlineTableController, choseDownloadVideoForBlock block: CourseBlock) {
        
        if isDownloadSettingsValid() {
            environment.dataManager.interface?.downloadVideos(withIDs: [block.blockID], courseID: courseID)
            environment.analytics.trackSingleVideoDownload(block.blockID, courseID: courseID, unitURL: block.webURL?.absoluteString)
        }
        else {
            showOverlay(withMessage: Strings.noWifiMessage)
        }
    }
    
    func outlineTableController(controller: CourseOutlineTableController, choseBlock block: CourseBlock, withParentID parent : CourseBlockID) {
        self.environment.router?.showContainerForBlockWithID(blockID: block.blockID, type:block.displayType, parentID: parent, courseID: courseQuerier.courseID, fromController:self, forMode: courseOutlineMode)
    }
    
    func outlineTableControllerReload(controller: CourseOutlineTableController) {
        courseQuerier.needsRefresh = true
        reload()
    }
    
    //MARK: PullRefreshControllerDelegate
    public func refreshControllerActivated(controller: PullRefreshController) {
        courseQuerier.needsRefresh = true
        reload()
    }
    
    //MARK: CourseContentPageViewControllerDelegate
    public func courseContentPageViewController(controller: CourseContentPageViewController, enteredBlockWithID blockID: CourseBlockID, parentID: CourseBlockID) {
        self.blockIDStream.backWithStream(courseQuerier.parentOfBlockWithID(blockID: parentID))
        self.tableController.highlightedBlockID = blockID
    }
    
    //MARK: LastAccessedControllerDeleagte
    public func courseLastAccessedControllerDidFetchLastAccessedItem(item: CourseLastAccessed?) {
        if let lastAccessedItem = item {
            self.tableController.showLastAccessedWithItem(item: lastAccessedItem)
        }
        else {
            self.tableController.hideLastAccessed()
        }
        
    }
    
    //MARK:- LoadStateViewReloadSupport method
    func loadStateViewReload() {
        reload()
    }
}

extension CourseOutlineViewController {
    
    public func t_setup() -> OEXStream<Void> {
        return rowsLoader.map { _ in
        }
    }
    
    public func t_currentChildCount() -> Int {
        return tableController.groups.count
    }
    
    public func t_populateLastAccessedItem(item : CourseLastAccessed) -> Bool {
        self.tableController.showLastAccessedWithItem(item: item)
        return self.tableController.tableView.tableHeaderView != nil
        
    }
    
    public func t_didTriggerSetLastAccessed() -> Bool {
        return t_hasTriggeredSetLastAccessed
    }
    
    public func t_tableView() -> UITableView {
        return self.tableController.tableView
    }
    
}
