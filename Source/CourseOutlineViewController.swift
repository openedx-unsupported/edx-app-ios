//
//  CourseOutlineViewController.swift
//  edX
//
//  Created by Akiva Leffert on 4/30/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import UIKit

public class CourseOutlineViewController : UIViewController, CourseBlockViewController, CourseOutlineTableControllerDelegate,  CourseOutlineModeControllerDelegate {

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
    
    private let blockLoader = BackedStream<CourseBlock>()
    private let headersLoader = BackedStream<[CourseBlock]>()
    private let rowsLoader = BackedStream<[(CourseBlockID, [CourseBlock])]>()
    private let lastAccessedLoader = BackedStream<(CourseBlock, CourseLastAccessed)>()
    
    private let loadController : LoadStateViewController
    private let insetsController : ContentInsetsController
    private let modeController : CourseOutlineModeController
    
    
    /// Strictly a test variable used as a trigger flag. Not to be used out of the test scope
    private var t_hasTriggeredSetLastAccessed = false
    
    public var blockID : CourseBlockID? {
        return rootID
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
        
        super.init(nibName: nil, bundle: nil)
        
        modeController.delegate = self
        
        webController = OpenOnWebController(inViewController: self)
        addChildViewController(tableController)
        tableController.didMoveToParentViewController(self)
        tableController.delegate = self
        
        navigationItem.rightBarButtonItems = [webController.barButtonItem,modeController.barItem]
        navigationItem.backBarButtonItem = UIBarButtonItem(title: " ", style: .Plain, target: nil, action: nil)
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
        insetsController.supportDownloadsProgress(interface : environment.dataManager.interface, styles : environment.styles)
        
        self.view.setNeedsUpdateConstraints()
        
        self.blockLoader.backWithStream(courseQuerier.blockWithID(self.blockID).dropFailuresAfterSuccess())
        loadContentIfNecessary()
        addListeners()
        
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        loadContentIfNecessary()
        loadLastAccessed()
        saveLastAccessed()
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
        self.webController.updateButtonForURL(block.webURL)
    }
    
    public func viewControllerForCourseOutlineModeChange() -> UIViewController {
        return self
    }
    
    public func courseOutlineModeChanged(courseMode: CourseOutlineMode) {
        headersLoader.removeBacking()
        loadContentIfNecessary()
    }
    
    private func emptyState() -> LoadState {
        switch modeController.currentMode {
        case .Full:
            return LoadState.failed(error : NSError.oex_courseContentLoadError())
        case .Video:
            let message = OEXLocalizedString("NO_VIDEOS_TRY_MODE_SWITCHER", nil)
            let attributedMessage = loadController.messageStyle.attributedStringWithText(message)
            let formattedMessage = attributedMessage.oex_formatWithParameters(["video_icon" : Icon.CourseModeVideo.attributedTextWithSize(loadController.messageStyle.size)])
            return LoadState.empty(icon: Icon.CourseModeFull, attributedMessage : formattedMessage)
        }
    }
    
    private func showErrorIfNecessary(error : NSError) {
        if self.loadController.state.isInitial {
            self.loadController.state = LoadState.failed(error : error)
        }
    }
    
    private func loadedHeaders(headers : [CourseBlock]) {
        let children = headers.map {header in
            return self.courseQuerier.childrenOfBlockWithID(header.blockID, forMode: self.modeController.currentMode).map {
                return (header.blockID, $0)
            }
        }
        rowsLoader.backWithStream(joinStreams(children))
    }
    
    private func addListeners() {
        lastAccessedLoader.listen(self) {[weak self] info in
            info.ifSuccess {
                let block = $0.0
                var item = $0.1
                item.moduleName = block.name
                
                OEXInterface.sharedInterface().setLastAccessedSubsectionWith(item.moduleId, andSubsectionName: block.name, forCourseID: self?.courseID, onTimeStamp: OEXDateFormatting.serverStringWithDate(NSDate()))
                self?.tableController.showLastAccessedWithItem(item)
            }
        }
        
        blockLoader.listen(self) {[weak self] block in
            block.ifSuccess {
                self?.setupNavigationItem($0)
            }
        }
        
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
            success : {[weak self] children in
                if let owner = self, nodes = owner.headersLoader.value {
                    owner.tableController.nodes = nodes
                    owner.tableController.children = Dictionary(elements: children)
                    owner.tableController.tableView.reloadData()
                    owner.loadController.state = nodes.count == 0 ? owner.emptyState() : .Loaded
                }
            },
            failure : {[weak self] error in
                self?.showErrorIfNecessary(error)
            }
        )
    }
    
    private func loadContentIfNecessary() {
        if !headersLoader.hasBacking {
            headersLoader.backWithStream(courseQuerier.childrenOfBlockWithID(blockID, forMode: modeController.currentMode))
        }
    }

    // MARK: Outline Table Delegate
    
    func outlineTableController(controller: CourseOutlineTableController, choseDownloadVideosRootedAtBlock block: CourseBlock) {
        let hasWifi = environment.reachability.isReachableViaWiFi() ?? false
        if OEXInterface.shouldDownloadOnlyOnWifi() && !hasWifi {
            self.loadController.showOverlayError(OEXLocalizedString("NO_WIFI_MESSAGE", nil))
            return;
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
    
    //MARK: Last Accessed
    
    private var canShowLastAccessed : Bool {
        // We only show at the root level
        return blockID == nil
    }
    
    private var canUpdateLastAccessed : Bool {
        return blockID != nil
    }

    func loadLastAccessed() {
        if !canShowLastAccessed {
            return
        }
    
        if let firstLoad = OEXInterface.sharedInterface().getLastAccessedSectionForCourseID(self.courseID) {
            let blockStream = expandAccessStream(Stream(value : firstLoad))
            lastAccessedLoader.backWithStream(blockStream)
        }
        
        let request = UserAPI.requestLastVisitedModuleForCourseID(courseID)
        let lastAccessed = self.environment.networkManager.streamForRequest(request)
        lastAccessedLoader.backWithStream(expandAccessStream(lastAccessed))
        
//            lastAccessedLoader.b
//            lastAccessed.then{ [weak self] lastAccessedItem -> Void in
//                
//                if let owner = self {
//                    owner.lastAccessedLoader.backWithStream(owner.courseQuerier.blockWithID(lastAccessedItem.moduleId))
//                    lastAccessedLoader.listenOnce (self) { [weak self] blockResult in
//                        if let outlineVC = self {
//                            var mutableLastAccessedItem = CourseLastAccessed(moduleId: lastAccessedItem.moduleId, moduleName: courseBlock.name)
//                            outlineVC.tableController.showLastAccessedWithItem(mutableLastAccessedItem)
//                            OEXInterface.sharedInterface().setLastAccessedSubsectionWith(mutableLastAccessedItem.moduleId, andSubsectionName: mutableLastAccessedItem.moduleName, forCourseID: outlineVC.courseID, onTimeStamp: OEXDateFormatting.serverStringWithDate(NSDate()))
//                        }
//                    }
//                }
//                
//            }
//        }
//        
//        else {
//            if let lastAccessed =  {
//                let block = courseQuerier.blockWithID(lastAccessed.moduleId)
//                block.then{ [weak self] fetchedBlock -> Void in
//                    if let owner = self {
//
//                    }
//                }
//            }
//        }
    }
    
    func saveLastAccessed() {
        if !canUpdateLastAccessed {
            return
        }
        
        if let currentCourseBlockID = self.blockID {
            t_hasTriggeredSetLastAccessed = true
            let request = UserAPI.setLastVisitedModuleForBlockID(self.courseID, module_id: currentCourseBlockID)
            expandAccessStream(self.environment.networkManager.streamForRequest(request)).extendLifetimeUntilFirstResult {result in
                result.ifSuccess() {info in
                    let block = info.0
                    let lastAccessedItem = info.1
                    OEXInterface.sharedInterface().setLastAccessedSubsectionWith(lastAccessedItem.moduleId, andSubsectionName: block.name, forCourseID: self.courseID, onTimeStamp: OEXDateFormatting.serverStringWithDate(NSDate()))
                }
            }
        }
    }
}

extension CourseOutlineViewController {
    
    public func t_setup() -> Stream<Void> {
        return rowsLoader.map { _ in
        }
    }
    
    public func t_currentChildCount() -> Int {
        return tableController.nodes.count
    }
    
    public func t_populateLastAccessedItem(item : CourseLastAccessed) -> Bool {
        self.tableController.showLastAccessedWithItem(item)
        return self.tableController.tableView.tableHeaderView != nil

    }
    
    public func t_didTriggerSetLastAccessed() -> Bool {
        return t_hasTriggeredSetLastAccessed
    }
    
}
