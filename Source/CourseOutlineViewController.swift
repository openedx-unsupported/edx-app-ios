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
        
        public init(dataManager : DataManager, reachability : Reachability, router : OEXRouter, styles : OEXStyles) {
            self.reachability = reachability
            self.router = router
            self.dataManager = dataManager
            self.styles = styles
        }
    }

    
    private var rootID : CourseBlockID?
    private var environment : Environment
    
    private var openURLButtonItem : UIBarButtonItem?
    
    private let courseQuerier : CourseOutlineQuerier
    private let tableController : CourseOutlineTableController
    
    private var loader : Promise<[CourseBlock]>?
    private var setupFinished : Promise<Void>?
    
    private let loadController : LoadStateViewController
    private let insetsController : ContentInsetsController
    private let modeController : CourseOutlineModeController
    
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
        insetsController.supportLastAccessed(interface: environment.dataManager.interface, styles: environment.styles)
        
        self.view.setNeedsUpdateConstraints()
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        loadContentIfNecessary()
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
    
    private func setupNavigationItem() {
        let blockLoader = courseQuerier.blockWithID(self.blockID)
        blockLoader.then { [weak self] block in
            self?.webController.updateButtonForURL(block.webURL)
        }
        blockLoader.then {[weak self] block in
            self?.navigationItem.title = block.name
        }
        self.navigationItem.title = blockLoader.value?.name
    }
    
    public func viewControllerForCourseOutlineModeChange() -> UIViewController {
        return self
    }
    
    public func courseOutlineModeChanged(courseMode: CourseOutlineMode) {
        loader = nil
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
    
    private func loadContentIfNecessary() {
        setupNavigationItem()
    
        if loader == nil {
            let action = courseQuerier.childrenOfBlockWithID(blockID, forMode: modeController.currentMode)
            loader = action
            
            setupFinished = action.then {[weak self] nodes -> Promise<Void> in
                if let owner = self {
                    let promises = nodes.map {(node : CourseBlock) -> Promise<(CourseBlockID, [CourseBlock])> in
                        let promise = owner.courseQuerier.childrenOfBlockWithID(node.blockID, forMode: owner.modeController.currentMode).then {blocks in
                                return (node.blockID, blocks)
                        }
                        return promise
                    }
                    
                    return when(promises).then {[weak self] children -> Void in
                        if let owner = self {
                            owner.tableController.nodes = nodes
                            owner.tableController.children = Dictionary(elements: children)
                            owner.tableController.tableView.reloadData()
                            owner.loadController.state = nodes.count == 0 ? owner.emptyState() : .Loaded
                        }
                    }
                }
                // If owner is nil, then the owning controller is dealloced, so just fail quietly
                return Promise {fulfill, reject in
                    reject(NSError.oex_courseContentLoadError())
                }
            }
            setupFinished?.catch {[weak self] error in
                if let state = self?.loadController.state where state.isInitial {
                    self?.loadController.state = LoadState.failed(error : error)
                }
                // Otherwise, we already have content so stifle error
            } as Void?
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
        }.then {[weak self] videos -> Void in
            if let owner = self {
                let interface = self?.environment.dataManager.interface
                interface?.downloadVideosWithIDs(videos, courseID: owner.courseID)
            }
        }
    }
    
    func outlineTableController(controller: CourseOutlineTableController, choseBlock block: CourseBlock, withParentID parent : CourseBlockID) {
        self.environment.router?.showContainerForBlockWithID(block.blockID, type:block.displayType, parentID: parent, courseID: courseQuerier.courseID, fromController:self)
    }
}

extension CourseOutlineViewController {
    
    public func t_setup() -> Promise<Void> {
        return setupFinished!
    }
    
    public func t_currentChildCount() -> Int {
        return tableController.nodes.count
    }
    
}
