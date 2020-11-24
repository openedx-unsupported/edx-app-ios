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
    private let tableController : CourseOutlineTableController
    
    private let blockIDStream = BackedStream<CourseBlockID?>()
    private let headersLoader = BackedStream<CourseOutlineQuerier.BlockGroup>()
    private let rowsLoader = BackedStream<[CourseOutlineQuerier.BlockGroup]>()
    private let courseDateBannerLoader = BackedStream<(CourseDateBannerModel)>()

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
        courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID: courseID, environment: environment)
        
        loadController = LoadStateViewController()
        insetsController = ContentInsetsController()
        courseOutlineMode = mode ?? .full
        tableController = CourseOutlineTableController(environment: environment, courseID: courseID, forMode: courseOutlineMode, courseBlockID: rootID)
        lastAccessedController = CourseLastAccessedController(blockID: rootID , dataManager: environment.dataManager, networkManager: environment.networkManager, courseQuerier: courseQuerier, forMode: courseOutlineMode)
        
        super.init(env: environment, shouldShowOfflineSnackBar: false)
        
        addObserver()
        lastAccessedController.delegate = self
        
        addChild(tableController)
        tableController.didMove(toParent: self)
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
        
        insetsController.setupInController(owner: self, scrollView : tableController.tableView)
        view.setNeedsUpdateConstraints()
        addListeners()
        setAccessibilityIdentifiers()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lastAccessedController.loadLastAccessed(forMode: courseOutlineMode)
        lastAccessedController.saveLastAccessed()
        loadCourseStream()
        
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
        loadController.insets = UIEdgeInsets(top: topLayoutGuide.length, left: 0, bottom: bottomLayoutGuide.length, right : 0)
        
        tableController.view.snp.remakeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
        super.updateViewConstraints()
    }
    
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        insetsController.updateInsets()
    }
    
    override func reloadViewData() {
        reload()
    }

    private func setAccessibilityIdentifiers() {
        view.accessibilityIdentifier = "CourseOutlineViewController:view"
        tableController.tableView.accessibilityIdentifier = "CourseOutlineViewController:course-outline-table-view"
        loadController.view.accessibilityIdentifier = "CourseOutlineViewController:load-state-controller-view"
    }
    
    private func setupNavigationItem(block : CourseBlock) {
        navigationItem.title = (courseOutlineMode == .video && rootID == nil) ? Strings.Dashboard.courseVideos : block.displayName
    }
    
    private func addObserver() {
        NotificationCenter.default.oex_addObserver(observer: self, name: NOTIFICATION_SHIFT_COURSE_DATES) { _, observer, _ in
            observer.refreshCourseOutlineController()
        }
    }
    
    private func loadCourseOutlineStream() {
        let courseOutlineStream = joinStreams(courseQuerier.rootID, courseQuerier.blockWithID(id: blockID))

        courseOutlineStream.extendLifetimeUntilFirstResult (success : { [weak self] (rootID, block) in
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
            }, failure: {
                Logger.logError("ANALYTICS", "Unable to load block: \($0)")
        })
    }
    
    private func loadCourseBannerStream() {
        let courseBannerRequest = CourseDateBannerAPI.courseDateBannerRequest(courseID: courseID)
        let courseBannerStream = environment.networkManager.streamForRequest(courseBannerRequest)
        courseDateBannerLoader.backWithStream(courseBannerStream)
        
        courseBannerStream.listen(self) { [weak self] result in
            switch result {
            case .success(let courseBanner):
                self?.loadCourseDateBannerView(courseBanner: courseBanner)
                break
                
            case .failure(let error):
                self?.hideCourseBannerView()
                Logger.logError("DatesResetBanner", "Unable to load dates reset banner: \(error.localizedDescription)")
                break
            }
        }
    }
    
    private func loadCourseStream() {
        loadController.state = .Initial
        loadCourseOutlineStream()
        loadCourseBannerStream()
        reload()
    }
    
    private func loadCourseDateBannerView(courseBanner: CourseDateBannerModel) {
        if courseBanner.hasEnded {
            tableController.hideCourseDateBanner()
        } else {
            tableController.showCourseDateBanner(bannerInfo: courseBanner.bannerInfo)
        }
    }
    
    private func hideCourseBannerView() {
        tableController.hideCourseDateBanner()
    }
    
    private func reload() {
        blockIDStream.backWithStream(OEXStream(value : self.blockID))
    }
    
    private func emptyState() -> LoadState {
        return LoadState.empty(icon: .UnknownError, message : (courseOutlineMode == .video) ? Strings.courseVideoUnavailable : Strings.coursewareUnavailable)
    }
    
    private func showErrorIfNecessary(error : NSError) {
        if loadController.state.isInitial {
            loadController.state = LoadState.failed(error: error)
        }
    }
    
    private func addBackStreams() {
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
        
        blockIDStream.backWithStream(OEXStream(value: rootID))
    }
    
    private func loadHeaderStream() {
        headersLoader.listen(self, success: { [weak self] headers in
                self?.setupNavigationItem(block: headers.block)
            }, failure: {[weak self] error in
                self?.showErrorIfNecessary(error: error)
            }
        )
    }
    
    private func loadRowsStream() {
        rowsLoader.listen(self, success : { [weak self] groups in
                if let owner = self {
                    owner.tableController.groups = groups
                    owner.tableController.tableView.reloadData()
                    owner.loadController.state = groups.count == 0 ? owner.emptyState() : .Loaded
                }
            }, failure : {[weak self] error in
                self?.showErrorIfNecessary(error: error)
            }, finally: {[weak self] in
                if let active = self?.rowsLoader.active, !active {
                    self?.tableController.refreshController.endRefreshing()
                }
            }
        )
    }
    
    private func loadBackedStreams() {
        loadHeaderStream()
        loadRowsStream()
    }
    
    private func addListeners() {
        addBackStreams()
        loadBackedStreams()
    }
    
    private func canDownload() -> Bool {
        return environment.dataManager.interface?.canDownload() ?? false
    }
    
    // MARK: Outline Table Delegate
    
    func outlineTableControllerChoseShowDownloads(controller: CourseOutlineTableController) {
        environment.router?.showDownloads(from: self)
    }
    
    func outlineTableController(controller: CourseOutlineTableController, choseDownloadVideos videos: [OEXHelperVideoDownload], rootedAtBlock block:CourseBlock) {
        if canDownload() {
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
            showOverlay(withMessage: environment.interface?.networkErrorMessage() ?? Strings.noWifiMessage)
        }
    }
    
    func outlineTableController(controller: CourseOutlineTableController, choseDownloadVideoForBlock block: CourseBlock) {
        
        if canDownload() {
            environment.dataManager.interface?.downloadVideos(withIDs: [block.blockID], courseID: courseID)
            environment.analytics.trackSingleVideoDownload(block.blockID, courseID: courseID, unitURL: block.webURL?.absoluteString)
        }
        else {
            showOverlay(withMessage: environment.interface?.networkErrorMessage() ?? Strings.noWifiMessage)
        }
    }
    
    func outlineTableController(controller: CourseOutlineTableController, choseBlock block: CourseBlock, withParentID parent : CourseBlockID) {
        environment.router?.showContainerForBlockWithID(blockID: block.blockID, type:block.displayType, parentID: parent, courseID: courseQuerier.courseID, fromController:self, forMode: courseOutlineMode)
    }
    
    func outlineTableControllerReload(controller: CourseOutlineTableController) {
        courseQuerier.needsRefresh = true
        reload()
    }
    
    func resetCourseDate(controller: CourseOutlineTableController) {
        trackDatesShiftTapped()
        hideCourseBannerView()
        
        let request = CourseDateBannerAPI.courseDatesResetRequest(courseID: courseID)
        environment.networkManager.taskForRequest(request) { [weak self] result  in
            guard let weakSelf = self else { return }
            if let _ = result.error {
                weakSelf.trackDatesShiftEvent(success: false)
                weakSelf.showDateResetSnackBar(message: Strings.Coursedates.ResetDate.errorMessage)
            } else {
                weakSelf.trackDatesShiftEvent(success: true)
                weakSelf.showSnackBar()
                weakSelf.postCourseDateResetNotification()
            }
        }
    }
    
    private func trackDatesShiftTapped() {
        guard let courseMode = environment.dataManager.enrollmentManager.enrolledCourseWithID(courseID: courseID)?.mode else { return }
        environment.analytics.trackDatesShiftButtonTapped(screenName: AnalyticsScreenName.CourseDashboard, courseMode: courseMode)
    }
    
    private func trackDatesShiftEvent(success: Bool) {
        guard let courseMode = environment.dataManager.enrollmentManager.enrolledCourseWithID(courseID: courseID)?.mode else { return }
        environment.analytics.trackDatesShiftEvent(screenName: AnalyticsScreenName.CourseDashboard, courseMode: courseMode, success: success)
    }
    
    private func showSnackBar() {
        showDateResetSnackBar(message: Strings.Coursedates.toastSuccessMessage, buttonText: Strings.Coursedates.viewAllDates, showButton: true) { [weak self] in
            if let weakSelf = self {
                weakSelf.environment.router?.showDatesTabController(controller: weakSelf)
                weakSelf.hideSnackBar()
            }
        }
    }
    
    private func postCourseDateResetNotification() {
        NotificationCenter.default.post(Notification(name: Notification.Name(rawValue: NOTIFICATION_SHIFT_COURSE_DATES)))
    }
    
    private func refreshCourseOutlineController() {
        hideCourseBannerView()
        courseQuerier.needsRefresh = true
        loadBackedStreams()
        loadCourseStream()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: PullRefreshControllerDelegate
    public func refreshControllerActivated(controller: PullRefreshController) {
        refreshCourseOutlineController()
    }
    
    //MARK: CourseContentPageViewControllerDelegate
    public func courseContentPageViewController(controller: CourseContentPageViewController, enteredBlockWithID blockID: CourseBlockID, parentID: CourseBlockID) {
        blockIDStream.backWithStream(courseQuerier.parentOfBlockWithID(blockID: parentID))
        tableController.highlightedBlockID = blockID
    }
    
    //MARK: LastAccessedControllerDeleagte
    public func courseLastAccessedControllerDidFetchLastAccessedItem(item: CourseLastAccessed?) {
        if let lastAccessedItem = item {
            tableController.showLastAccessedWithItem(item: lastAccessedItem)
        }
        else {
            tableController.hideLastAccessed()
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
        tableController.showLastAccessedWithItem(item: item)
        return tableController.tableView.tableHeaderView != nil
        
    }
    
    public func t_didTriggerSetLastAccessed() -> Bool {
        return t_hasTriggeredSetLastAccessed
    }
    
    public func t_tableView() -> UITableView {
        return tableController.tableView
    }
    
}
