//
//  CourseOutlineViewController.swift
//  edX
//
//  Created by Akiva Leffert on 4/30/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import UIKit

public class CourseOutlineViewController : UIViewController, CourseOutlineTableControllerDelegate, CourseBlockViewController {

    public struct Environment {
        weak var router : OEXRouter?
        let dataManager : DataManager
        let styles : OEXStyles
        
        public init(dataManager : DataManager, router : OEXRouter, styles : OEXStyles) {
            self.router = router
            self.dataManager = dataManager
            self.styles = styles
        }
    }

    
    private var rootID : CourseBlockID?
    private var environment : Environment
    
    private var currentMode : CourseOutlineMode = .Full  // TODO
    
    private let courseQuerier : CourseOutlineQuerier
    private let tableController : CourseOutlineTableController = CourseOutlineTableController()
    
    private var loader : Promise<[CourseBlock]>?
    private var setupFinished : Promise<Void>?
    
    private let loadController : LoadStateViewController
    private let insetsController : ContentInsetsController
    
    public var blockID : CourseBlockID? {
        return rootID
    }
    
    public var courseID : String {
        return courseQuerier.courseID
    }
    
    public init(environment: Environment, courseID : String, rootID : CourseBlockID?) {
        self.rootID = rootID
        self.environment = environment
        courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID)
        
        loadController = LoadStateViewController(styles: environment.styles)
        insetsController = ContentInsetsController(styles : self.environment.styles)
        insetsController.supportOfflineMode()
        
        super.init(nibName: nil, bundle: nil)
        
        addChildViewController(tableController)
        tableController.didMoveToParentViewController(self)
        tableController.delegate = self
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
        blockLoader.then {[weak self] block in
            self?.navigationItem.title = block.name
        }
        self.navigationItem.title = blockLoader.value?.name
    }
    
    private func loadContentIfNecessary() {
        setupNavigationItem()
    
        if loader == nil {
            let action = courseQuerier.childrenOfBlockWithID(self.blockID, mode: currentMode)
            loader = action
            
            setupFinished = action.then {[weak self] nodes -> Promise<Void> in
                if let owner = self {
                    owner.tableController.nodes = nodes
                    var children : [CourseBlockID : Promise<[CourseBlock]>] = [:]
                    let promises = nodes.map {(node : CourseBlock) -> Promise<[CourseBlock]> in
                        let promise = owner.courseQuerier.childrenOfBlockWithID(node.blockID, mode: owner.currentMode)
                        children[node.blockID] = promise
                        return promise
                    }
                    owner.tableController.children = children
                    
                    return when(promises).then {_ -> Void in
                        self?.tableController.tableView.reloadData()
                        self?.loadController.state = .Loaded
                    }
                }
                // If owner is nil, then the owning controller is dealloced, so just fail quietly
                return Promise {fulfill, reject in
                    reject(NSError.oex_courseContentLoadError())
                }
            }
            setupFinished?.catch {[weak self] error in
                if let state = self?.loadController.state where state.isInitial {
                    self?.loadController.state = .Failed(error : error, icon : nil, message : nil)
                }
                // Otherwise, we already have content so stifle error
            } as Void?
        }
    }
    
    func outlineTableController(controller: CourseOutlineTableController, choseBlock block: CourseBlock, withParentID parent : CourseBlockID) {
        self.environment.router?.showContainerForBlockWithID(block.blockID, type:block.type.displayType, parentID: parent, courseID: courseQuerier.courseID, fromController:self)
    }
}

extension CourseOutlineViewController {
    
    public func t_setup() -> Promise<Void> {
        return setupFinished!
    }
    
}
