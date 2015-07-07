//
//  CourseOutlineViewController.swift
//  edX
//
//  Created by Akiva Leffert on 4/30/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import UIKit

public class CourseOutlineViewController : UIViewController, CourseBlockViewController, CourseOutlineTableControllerDelegate,  CourseOutlineModeControllerDelegate, CourseContentPageViewControllerDelegate, DownloadProgressViewControllerDelegate, CourseLastAccessedControllerDelegate {

    public struct Environment {
        let reachability : Reachability
        weak var router : OEXRouter?
        let dataManager : DataManager
        let styles : OEXStyles
        let networkManager : NetworkManager
        
        public init(dataManager : DataManager, reachability : Reachability, router : OEXRouter, styles : OEXStyles, networkManager : NetworkManager) {
            self.reachability = reachability
            self.router = router
            self.dataManager = dataManager
            self.styles = styles
            self.networkManager = networkManager
        }
    }
    
    private var rootID : CourseBlockID?
    private var environment : Environment
    
    private let courseQuerier : CourseOutlineQuerier
    private let tableController : CourseOutlineTableController
    
    private let blockIDStream = BackedStream<CourseBlockID?>()
    private let headersLoader = BackedStream<CourseOutlineQuerier.BlockGroup>()
    private let rowsLoader = BackedStream<[CourseOutlineQuerier.BlockGroup]>()
    
    private let loadController : LoadStateViewController
    private let insetsController : ContentInsetsController
    private let modeController : CourseOutlineModeController
    private var lastAccessedController : CourseLastAccessedController
    
    
    /// Strictly a test variable used as a trigger flag. Not to be used out of the test scope
    private var t_hasTriggeredSetLastAccessed = false
    
    public var blockID : CourseBlockID? {
        return blockIDStream.value ?? nil
    }
    
    public var courseID : String {
        return courseQuerier.courseID
    }
    
    private var webController : OpenOnWebController!
    
    public init(environment: Environment, courseID : String, rootID : CourseBlockID?) {
        self.rootID = rootID
        self.environment = environment
        courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID)
        
        loadController = LoadStateViewController(styles: environment.styles)
        insetsController = ContentInsetsController()
        
        modeController = environment.dataManager.courseDataManager.freshOutlineModeController()
        tableController = CourseOutlineTableController(courseID: courseID)
        
        lastAccessedController = CourseLastAccessedController(blockID: rootID , dataManager: environment.dataManager, networkManager: environment.networkManager, courseQuerier: courseQuerier)
        
        super.init(nibName: nil, bundle: nil)
        
        lastAccessedController.delegate = self
        modeController.delegate = self
        
        webController = OpenOnWebController(inViewController: self)
        addChildViewController(tableController)
        tableController.didMoveToParentViewController(self)
        tableController.delegate = self
        
        navigationItem.rightBarButtonItems = [webController.barButtonItem,modeController.barItem]
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
        
        self.blockIDStream.backWithStream(Stream(value: rootID))
    }

    public required init(coder aDecoder: NSCoder) {
        // required by the compiler because UIViewController implements NSCoding,
        // but we don't actually want to serialize these things
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = self.environment.styles.standardBackgroundColor()
        view.addSubview(tableController.view)
        
        loadController.setupInController(self, contentView:tableController.view)
        
        insetsController.setupInController(self, scrollView : self.tableController.tableView)
        insetsController.supportOfflineMode(styles: environment.styles)
        insetsController.supportDownloadsProgress(interface : environment.dataManager.interface, styles : environment.styles, delegate : self)
        
        self.view.setNeedsUpdateConstraints()
        
        addListeners()
        
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        lastAccessedController.loadLastAccessed(forMode: modeController.currentMode)
        lastAccessedController.saveLastAccessed()
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
    
    private func setupNavigationItem(block : CourseBlock) {
        self.navigationItem.title = block.name
        self.webController.URL = block.webURL
    }
    
    public func viewControllerForCourseOutlineModeChange() -> UIViewController {
        return self
    }
    
    public func courseOutlineModeChanged(courseMode: CourseOutlineMode) {
        headersLoader.removeBacking()
        lastAccessedController.loadLastAccessed(forMode: courseMode)
        self.blockIDStream.backWithStream(Stream(value : self.blockID))
    }
    
    private func emptyState() -> LoadState {
        switch modeController.currentMode {
        case .Full:
            return LoadState.failed(error : NSError.oex_courseContentLoadError())
        case .Video:
            let message = OEXLocalizedString("NO_VIDEOS_TRY_MODE_SWITCHER", nil)
            let attributedMessage = loadController.messageStyle.attributedStringWithText(message)
            let formattedMessage = attributedMessage.oex_formatWithParameters(["mode_switcher" : Icon.CourseModeVideo.attributedTextWithStyle(loadController.messageStyle)])
            let accessibilityMessage = message.oex_formatWithParameters(["mode_switcher" : OEXLocalizedString("COURSE_MODE_PICKER_DESCRIPTION", nil)])
            return LoadState.empty(icon: Icon.CourseModeFull, attributedMessage : formattedMessage, accessibilityMessage : accessibilityMessage)
        }
    }
    
    private func showErrorIfNecessary(error : NSError) {
        if self.loadController.state.isInitial {
            self.loadController.state = LoadState.failed(error : error)
        }
    }
    
    private func loadedHeaders(headers : CourseOutlineQuerier.BlockGroup) {
        self.setupNavigationItem(headers.block)
        let children = headers.children.map {header in
            return self.courseQuerier.childrenOfBlockWithID(header.blockID, forMode: self.modeController.currentMode)
        }
        rowsLoader.backWithStream(joinStreams(children))
    }
    
    private func addListeners() {
        blockIDStream.listen(self,
            success: {[weak self] blockID in
                self?.backHeadersLoaderWithBlockID(blockID)
            },
            failure: {[weak self] error in
                self?.headersLoader.backWithStream(Stream(error: error))
        })
        
        headersLoader.listen(self,
            success: {[weak self] headers in
                self?.loadedHeaders(headers)
            },
            failure: {[weak self] error in
                self?.rowsLoader.backWithStream(Stream(error: error))
                self?.showErrorIfNecessary(error)
            }
        )
        
        rowsLoader.listen(self,
            success : {[weak self] groups in
                if let owner = self, nodes = owner.headersLoader.value {
                    owner.tableController.groups = groups
                    owner.tableController.tableView.reloadData()
                    owner.loadController.state = groups.count == 0 ? owner.emptyState() : .Loaded
                }
            },
            failure : {[weak self] error in
                self?.showErrorIfNecessary(error)
            }
        )
    }
    
    private func backHeadersLoaderWithBlockID(blockID : CourseBlockID?) {
        self.headersLoader.backWithStream(courseQuerier.childrenOfBlockWithID(blockID, forMode: modeController.currentMode))
    }

    // MARK: Outline Table Delegate
    
    func outlineTableController(controller: CourseOutlineTableController, choseDownloadVideosRootedAtBlock block: CourseBlock) {
        let hasWifi = environment.reachability.isReachableViaWiFi() ?? false
        let onlyOnWifi = environment.dataManager.interface?.shouldDownloadOnlyOnWifi ?? false
        if onlyOnWifi && !hasWifi {
            self.loadController.showOverlayError(OEXLocalizedString("NO_WIFI_MESSAGE", nil))
            return
        }
        
        let children = courseQuerier.flatMapRootedAtBlockWithID(block.blockID) { block -> [(String)] in
            block.type.asVideo.map { _ in return [block.blockID] } ?? []
        }.listenOnce(self,
            success : { [weak self] videos in
                if let owner = self {
                    let interface = self?.environment.dataManager.interface
                    interface?.downloadVideosWithIDs(videos, courseID: owner.courseID)
                }
            },
            failure : {[weak self] error in
                self?.loadController.showOverlayError(error.localizedDescription)
            }
        )
    }
    
    func outlineTableController(controller: CourseOutlineTableController, choseBlock block: CourseBlock, withParentID parent : CourseBlockID) {
        self.environment.router?.showContainerForBlockWithID(block.blockID, type:block.displayType, parentID: parent, courseID: courseQuerier.courseID, fromController:self)
    }
    
    private func expandAccessStream(stream : Stream<CourseLastAccessed>) -> Stream<(CourseBlock, CourseLastAccessed)> {
        return stream.transform {[weak self] lastAccessed in
            return joinStreams(self?.courseQuerier.blockWithID(lastAccessed.moduleId) ?? Stream<CourseBlock>(), Stream(value: lastAccessed))
        }

    }
    
    //MARK: DownloadProgressViewControllerDelegate
    public func downloadProgressControllerChoseShowDownloads(controller: DownloadProgressViewController) {
        self.environment.router?.showDownloadsFromViewController(self)
    }
    
    //MARK: CourseContentPageViewControllerDelegate
    public func courseContentPageViewController(controller: CourseContentPageViewController, enteredItemInGroup blockID : CourseBlockID) {
        self.blockIDStream.backWithStream(courseQuerier.parentOfBlockWithID(blockID))
    }
    
    //MARK: LastAccessedControllerDeleagte
    public func courseLastAccessedControllerDidFetchLastAccessedItem(item: CourseLastAccessed?) {
        if let lastAccessedItem = item {
            self.tableController.showLastAccessedWithItem(lastAccessedItem)
        }
        else {
            self.tableController.hideLastAccessed()
        }
        
    }
}

extension CourseOutlineViewController {
    
    public func t_setup() -> Stream<Void> {
        return rowsLoader.map { _ in
        }
    }
    
    public func t_currentChildCount() -> Int {
        return tableController.groups.count
    }
    
    public func t_populateLastAccessedItem(item : CourseLastAccessed) -> Bool {
        self.tableController.showLastAccessedWithItem(item)
        return self.tableController.tableView.tableHeaderView != nil

    }
    
    public func t_didTriggerSetLastAccessed() -> Bool {
        return t_hasTriggeredSetLastAccessed
    }
    
}
