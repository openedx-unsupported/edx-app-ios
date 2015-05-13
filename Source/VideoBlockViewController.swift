//
//  VideoBlockViewController.swift
//  edX
//
//  Created by Akiva Leffert on 5/6/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import UIKit

private let StandardVideoAspectRatio : CGFloat = 0.6

class VideoBlockViewController : UIViewController, CourseBlockViewController {

    class Environment : NSObject {
        let courseDataManager : CourseDataManager
        let interface : OEXInterface?
        let styles : OEXStyles?
        
        init(courseDataManager : CourseDataManager, interface : OEXInterface?, styles : OEXStyles?) {
            self.courseDataManager = courseDataManager
            self.interface = interface
            self.styles = styles
        }
    }

    let environment : Environment
    let blockID : CourseBlockID
    let courseQuerier : CourseOutlineQuerier
    let videoController : OEXVideoPlayerInterface
    
    var loadingSpinner : UIActivityIndicatorView?
    var loader : Promise<CourseBlock>?
    var video : OEXHelperVideoDownload?
    
    var noTranscriptMessage : EmptyMessageView?
    
    init(environment : Environment, blockID : CourseBlockID, courseID: String) {
        self.blockID = blockID
        self.environment = environment
        courseQuerier = environment.courseDataManager.querierForCourseWithID(courseID)
        videoController = OEXVideoPlayerInterface()
        
        super.init(nibName: nil, bundle: nil)
        
        addChildViewController(videoController)
        videoController.didMoveToParentViewController(self)
    }
    
    var courseID : String {
        return courseQuerier.courseID
    }

    required init(coder aDecoder: NSCoder) {
        // required by the compiler because UIViewController implements NSCoding,
        // but we don't actually want to serialize these things
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(videoController.view)
        videoController.view.alpha = 0
        videoController.view.setTranslatesAutoresizingMaskIntoConstraints(false)
        videoController.fadeInOnLoad = false
        
        noTranscriptMessage = EmptyMessageView(item: FontAwesome.FileTextO, message: OEXLocalizedString("NO_TRANSCRIPT", nil), styles : self.environment.styles)
        noTranscriptMessage!.alpha = 0
        view.addSubview(noTranscriptMessage!)
        
        view.backgroundColor = self.environment.styles?.neutralWhite()
        
        loadingSpinner = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        loadingSpinner!.startAnimating()
        view.addSubview(loadingSpinner!)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        loadVideoIfNecessary()
    }
    
    func loadVideoIfNecessary() {
        if loader == nil {
            let action = courseQuerier.blockWithID(self.blockID)
            loader = action
            action.then {[weak self] block -> CourseBlock in
                if let video = self?.environment.interface?.stateForVideoWithID(self?.blockID, courseID : self?.courseID) {
                    self?.showLoadedVideo(video)
                }
                else {
                    // Show video couldn't load
                }
                return block
            }
            .catch {error -> Void in
                // TODO show error state
            }
        }
    }
    
    override func updateViewConstraints() {
        loadingSpinner?.snp_updateConstraints {make in
            make.center.equalTo(view)
        }
        
        videoController.view.snp_updateConstraints {make in
            make.leading.equalTo(view)
            make.trailing.equalTo(view)
            make.top.equalTo(topLayoutGuide)
            make.height.equalTo(videoController.view.snp_width).multipliedBy(StandardVideoAspectRatio).offset(20)
        }
        
        noTranscriptMessage!.snp_updateConstraints {make in
            make.top.equalTo(videoController.view.snp_bottom)
            make.leading.equalTo(self.view)
            make.trailing.equalTo(self.view)
            make.bottom.equalTo(self.view).offset(-(self.navigationController?.toolbar.bounds.size.height ?? 0))
        }
        super.updateViewConstraints()
    }
    
    func showLoadedVideo(videoHelper : OEXHelperVideoDownload?) {
        video = videoHelper
        if let block = loader?.value?.type, summary = block.asVideo {
            view.setNeedsUpdateConstraints()
            view.updateConstraintsIfNeeded()
            navigationItem.title = summary.name
            
            dispatch_async(dispatch_get_main_queue()) {
                UIView.animateWithDuration(0.2 * NSTimeInterval(!self.isMovingToParentViewController())) {
                    self.videoController.view.alpha = 1
                    self.noTranscriptMessage?.alpha = 1
                    self.loadingSpinner?.alpha = 0
                }
            }
            videoController.playVideoFor(videoHelper)
        }
    }
    
}