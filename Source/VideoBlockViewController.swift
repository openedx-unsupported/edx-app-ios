//
//  VideoBlockViewController.swift
//  edX
//
//  Created by Akiva Leffert on 5/6/15.
//  Copyright (c) 2015 edX. All rights reserved.
//

import Foundation
import MediaPlayer
import UIKit

private let StandardVideoAspectRatio : CGFloat = 0.6

class VideoBlockViewController : UIViewController, CourseBlockViewController, OEXVideoPlayerInterfaceDelegate {

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
    
    var loader : Promise<CourseBlock>?
    var video : OEXHelperVideoDownload?
    
    var noTranscriptMessageView : IconMessageView?
    var contentView : UIView?
    
    let loadController : LoadStateViewController
    
    init(environment : Environment, blockID : CourseBlockID, courseID: String) {
        self.blockID = blockID
        self.environment = environment
        courseQuerier = environment.courseDataManager.querierForCourseWithID(courseID)
        videoController = OEXVideoPlayerInterface()
        loadController = LoadStateViewController(styles: environment.styles)
        
        super.init(nibName: nil, bundle: nil)
        
        addChildViewController(videoController)
        videoController.didMoveToParentViewController(self)
        videoController.delegate = self
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
        
        contentView = UIView(frame: CGRectZero)
        view.addSubview(contentView!)
        
        loadController.setupInView(view, contentView : contentView!)
        
        contentView!.addSubview(videoController.view)
        videoController.view.setTranslatesAutoresizingMaskIntoConstraints(false)
        videoController.fadeInOnLoad = false
        
        noTranscriptMessageView = IconMessageView(icon: .Transcript, message: OEXLocalizedString("NO_TRANSCRIPT", nil), styles : self.environment.styles)
        contentView!.addSubview(noTranscriptMessageView!)
        
        view.backgroundColor = self.environment.styles?.neutralWhite()
        view.setNeedsUpdateConstraints()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        loadVideoIfNecessary()
    }
    
    private func loadVideoIfNecessary() {
        if loader == nil {
            let action = courseQuerier.blockWithID(self.blockID)
            loader = action
            action.then {[weak self] block -> CourseBlock in
                if let video = self?.environment.interface?.stateForVideoWithID(self?.blockID, courseID : self?.courseID) {
                    self?.showLoadedVideo(video)
                }
                else {
                    self?.showError(nil)
                }
                return block
            }
            .catch {[weak self] error -> Void in
                self?.showError(error)
            }
        }
    }
    
    override func updateViewConstraints() {
        let bottomInset = self.navigationController?.toolbar.bounds.size.height ?? 0
        loadController.insets = UIEdgeInsetsMake(self.topLayoutGuide.length, 0, bottomInset, 0)
        contentView?.snp_updateConstraints {make in
            make.edges.equalTo(view)
        }
        
        videoController.view.snp_updateConstraints {make in
            make.leading.equalTo(contentView!)
            make.trailing.equalTo(contentView!)
            make.top.equalTo(topLayoutGuide)
            make.height.equalTo(videoController.view.snp_width).multipliedBy(StandardVideoAspectRatio).offset(20)
        }
        
        noTranscriptMessageView?.snp_updateConstraints {make in
            make.top.equalTo(videoController.view.snp_bottom)
            make.leading.equalTo(contentView!)
            make.trailing.equalTo(contentView!)
            make.bottom.equalTo(contentView!).offset(-bottomInset)
        }
        
        super.updateViewConstraints()
    }
    
    func movieTimedOut() {
        if videoController.moviePlayerController.fullscreen {
            UIAlertView(title: OEXLocalizedString("VIDEO_CONTENT_NOT_AVAILABLE", nil), message: "", delegate: nil, cancelButtonTitle: nil, otherButtonTitles: OEXLocalizedString("CLOSE", nil)).show()
        }
        else {
            loadController.showOverlayError(OEXLocalizedString("TIMEOUT_CHECK_INTERNET_CONNECTION", nil))
        }
    }
    
    private func showError(error : NSError?) {
        let state = LoadState.Failed(error: error, icon: .UnknownError, message: OEXLocalizedString("VIDEO_CONTENT_NOT_AVAILABLE", nil))
        loadController.setState(state, animated: true)
    }
    
    private func showLoadedVideo(videoHelper : OEXHelperVideoDownload?) {
        video = videoHelper
        if let block = loader?.value?.type, summary = block.asVideo {
            navigationItem.title = summary.name
            
            dispatch_async(dispatch_get_main_queue()) {
                self.loadController.setState(.Loaded, animated: !self.isMovingToParentViewController())
            }
            videoController.playVideoFor(videoHelper)
        }
        else {
            showError(nil)
        }
    }
    
}