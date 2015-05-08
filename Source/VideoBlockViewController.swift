//
//  VideoBlockViewController.swift
//  edX
//
//  Created by Akiva Leffert on 5/6/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import UIKit

class VideoBlockViewControllerEnvironment : NSObject {
    let courseDataManager : CourseDataManager
    
    init(courseDataManager : CourseDataManager) {
        self.courseDataManager = courseDataManager
    }
}

class VideoBlockViewController : UIViewController, CourseBlockViewController {
    let environment : VideoBlockViewControllerEnvironment
    let blockID : CourseBlockID
    let courseQuerier : CourseOutlineQuerier
    var loader : Promise<CourseBlock>?
    var video : OEXVideoSummary?
    
    init(environment : VideoBlockViewControllerEnvironment, blockID : CourseBlockID, courseID: String) {
        self.blockID = blockID
        self.environment = environment
        courseQuerier = environment.courseDataManager.querierForCourseWithID(courseID)
        super.init(nibName: nil, bundle: nil)
    }

    required init(coder aDecoder: NSCoder) {
        // required by the compiler because UIViewController implements NSCoding,
        // but we don't actually want to serialize these things
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.greenColor()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        loadVideoIfNecessary()
    }
    
    func loadVideoIfNecessary() {
        if loader == nil {
            let action = courseQuerier.blockWithID(self.blockID)
            loader = action
            action.then {[weak self] block in
                self?.showLoadedVideo()
            }
            .catch {error -> Void in
                // TODO show error state
            }
        }
    }
    
    func showLoadedVideo() {
        if let block = loader?.value?.type, summary = block.asVideo {
            // TODO show video
        }
    }
    
}