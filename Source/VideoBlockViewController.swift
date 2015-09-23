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

class VideoBlockViewController : UIViewController, CourseBlockViewController, OEXVideoPlayerInterfaceDelegate, ContainedNavigationController {

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
    let blockID : CourseBlockID?
    let courseQuerier : CourseOutlineQuerier
    let videoController : OEXVideoPlayerInterface
    
    let loader = BackedStream<CourseBlock>()
    
    var rotateDeviceMessageView : IconMessageView?
    var contentView : UIView?
    
    let loadController : LoadStateViewController
    
    init(environment : Environment, blockID : CourseBlockID?, courseID: String) {
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

    required init?(coder aDecoder: NSCoder) {
        // required by the compiler because UIViewController implements NSCoding,
        // but we don't actually want to serialize these things
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contentView = UIView(frame: CGRectZero)
        view.addSubview(contentView!)
        
        loadController.setupInController(self, contentView : contentView!)
        
        contentView!.addSubview(videoController.view)
        videoController.view.translatesAutoresizingMaskIntoConstraints = false
        videoController.fadeInOnLoad = false
        
        rotateDeviceMessageView = IconMessageView(icon: .Mobile, message: OEXLocalizedString("ROTATE_DEVICE", nil), styles: self.environment.styles, shouldRotateIcon : true)
        contentView!.addSubview(rotateDeviceMessageView!)
        
        view.backgroundColor = self.environment.styles?.standardBackgroundColor()
        view.setNeedsUpdateConstraints()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.loadVideoIfNecessary()
    }
    
    override func viewDidAppear(animated : Bool) {
        
        // There's a weird OS bug where the bottom layout guide doesn't get set properly until
        // the layout cycle after viewDidAppear so cause a layout cycle
        self.view.setNeedsUpdateConstraints()
        self.view.updateConstraintsIfNeeded()
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        super.viewDidAppear(animated)
    }
    
    private func loadVideoIfNecessary() {
        if !loader.hasBacking {
            loader.backWithStream(courseQuerier.blockWithID(self.blockID).firstSuccess())
            loader.listen (self,
                success : { [weak self] block in
                    if let video = self?.environment.interface?.stateForVideoWithID(self?.blockID, courseID : self?.courseID) {
                        self?.showLoadedBlock(block, forVideo: video)
                    }
                    else {
                        self?.showError(nil)
                    }
                }, failure : {[weak self] error in
                    self?.showError(error)
                }
            )
        }
    }
    
    override func updateViewConstraints() {
        loadController.insets = UIEdgeInsets(
            top: self.topLayoutGuide.length, left: 0,
            bottom: self.bottomLayoutGuide.length, right : 0)
        
        contentView?.snp_updateConstraints {make in
            make.edges.equalTo(view)
        }
        
        videoController.view.snp_updateConstraints {make in
            make.leading.equalTo(contentView!)
            make.trailing.equalTo(contentView!)
            if #available(iOS 9, *) {
                make.top.equalTo(self.topLayoutGuide.bottomAnchor)
            }
            else {
                make.top.equalTo(self.snp_topLayoutGuideBottom)
            }
            make.height.equalTo(videoController.view.snp_width).multipliedBy(StandardVideoAspectRatio).offset(20)
        }
        
        rotateDeviceMessageView?.snp_updateConstraints {make in
            make.top.equalTo(videoController.view.snp_bottom)
            make.leading.equalTo(contentView!)
            make.trailing.equalTo(contentView!)
            // There's a weird OS bug where the bottom layout guide doesn't get set properly until
            // the layout cycle after viewDidAppear, so use the parent in the mean time
            if #available(iOS 9, *) {
                make.bottom.equalTo(self.bottomLayoutGuide.topAnchor)
            }
            else {
                make.bottom.equalTo(self.snp_bottomLayoutGuideTop)
            }
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
        loadController.state = LoadState.failed(error, icon: .UnknownError, message: OEXLocalizedString("VIDEO_CONTENT_NOT_AVAILABLE", nil))
    }
    
    private func showLoadedBlock(block : CourseBlock, forVideo video: OEXHelperVideoDownload?) {
        if let summary = block.type.asVideo {
            navigationItem.title = summary.name
            
            dispatch_async(dispatch_get_main_queue()) {
                self.loadController.state = .Loaded
            }
            videoController.playVideoFor(video)
        }
        else {
            showError(nil)
        }
    }
    
    override func childViewControllerForStatusBarStyle() -> UIViewController? {
        return videoController
    }
    
    override func childViewControllerForStatusBarHidden() -> UIViewController? {
        return videoController
    }
    
}
