//
//  CourseOutlineViewController.swift
//  edX
//
//  Created by Akiva Leffert on 4/30/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import UIKit

class CourseOutlineViewControllerEnvironment : NSObject {
    weak var router : OEXRouter?
    
    init(router : OEXRouter) {
        self.router = router
    }
}


class CourseOutlineViewController : UIViewController, CourseOutlineTableControllerDelegate, CourseBlockViewController {
    private var courseID : String
    private var rootID : CourseBlockID
    private var environment : CourseOutlineViewControllerEnvironment
    
    private var loadState = LoadState.Initial
    private var currentMode : CourseOutlineMode = .Full  // TODO
    
    private let courseQuerier : CourseOutlineQuerier
    private let tableController : CourseOutlineTableController = CourseOutlineTableController()
    
    // TODO use whether this is loaded or to drive the main subview state
    private var loader : Promise<[CourseBlock]>?
    
    var blockID : CourseBlockID {
        return rootID
    }
    
    init(environment: CourseOutlineViewControllerEnvironment, courseID : String, rootID : CourseBlockID) {
        self.courseID = courseID
        self.rootID = rootID
        let stubCourseOutline = CourseOutline.freshCourseOutline(courseID) // TODO this is temporary stub data
        courseQuerier = CourseOutlineQuerier(courseID: courseID, outline: stubCourseOutline)
        self.environment = environment
        
        super.init(nibName: nil, bundle: nil)
        
        addChildViewController(tableController)
        tableController.didMoveToParentViewController(self)
        tableController.delegate = self
    }

    required init(coder aDecoder: NSCoder) {
        // required by the compiler because UIViewController implements NSCoding,
        // but we don't actually want to serialize these things
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.whiteColor()
        tableController.view.frame = view.bounds
        tableController.view.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        view.addSubview(tableController.view)
    }
    
    override func viewWillAppear(animated: Bool) {
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
                        self?.loadState = .Failed(error)
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
        self.environment.router?.showContainerForBlockWithID(block.blockID, ofType:block.type.rawValue, withParentID: parent, inCourse: courseID, fromController:self)
    }
}
