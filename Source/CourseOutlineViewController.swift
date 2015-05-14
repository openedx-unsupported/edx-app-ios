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

    public class Environment : NSObject {
        weak var router : OEXRouter?
        var dataManager : DataManager
        
        init(dataManager : DataManager, router : OEXRouter) {
            self.router = router
            self.dataManager = dataManager
        }
    }

    
    private var rootID : CourseBlockID
    private var environment : Environment
    
    private var loadState = LoadState.Initial
    private var currentMode : CourseOutlineMode = .Full  // TODO
    
    private let courseQuerier : CourseOutlineQuerier
    private let tableController : CourseOutlineTableController = CourseOutlineTableController()
    
    // TODO use whether this is loaded or to drive the main subview state
    private var loader : Promise<[CourseBlock]>?
    
    public var blockID : CourseBlockID {
        return rootID
    }
    
    public var courseID : String {
        return courseQuerier.courseID
    }
    
    public init(environment: Environment, courseID : String, rootID : CourseBlockID) {
        self.rootID = rootID
        self.environment = environment
        courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID)
        
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
        self.view.backgroundColor = UIColor.whiteColor()
        tableController.view.frame = view.bounds
        tableController.view.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        view.addSubview(tableController.view)
    }
    
    public override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        loadContentIfNecessary()
    }
    
    private func loadContentIfNecessary() {
        if loader == nil {
            let action = courseQuerier.childrenOfBlockWithID(self.rootID, mode: currentMode)
            loader = action
            
            action.then {[weak self] nodes -> Void in
                if let owner = self {
                    owner.tableController.nodes = nodes
                    var children : [CourseBlockID : Promise<[CourseBlock]>] = [:]
                    for node in nodes {
                        let promise = owner.courseQuerier.childrenOfBlockWithID(node.blockID, mode: owner.currentMode)
                        children[node.blockID] = promise
                        promise.finally {[weak self] in
                            if self?.tableController.allLoaded ?? false {
                                self?.tableController.tableView.reloadData()
                                self?.loadState = .Loaded
                            }
                            // TODO handle failure
                        }
                    }
                    owner.tableController.children = children
                }
                return
            }.catch {[weak self] error in
                if let state = self?.loadState {
                    switch state {
                    case .Initial:
                        self?.loadState = LoadState.Failed(error : error, icon : nil, message : nil)
                        break
                        // TODO Display error if necessary
                    default:
                        break
                        // Otherwise, we already have content so stifle error
                    }
                }
            } as Void
        }
    }
    
    func outlineTableController(controller: CourseOutlineTableController, choseBlock block: CourseBlock, withParentID parent : CourseBlockID) {
        self.environment.router?.showContainerForBlockWithID(block.blockID, type:block.type.displayType, parentID: parent, courseID: courseQuerier.courseID, fromController:self)
    }
}
