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
    
    typealias Environment = protocol<DataManagerProvider, OEXInterfaceProvider, ReachabilityProvider>

    let environment : Environment
    let blockID : CourseBlockID?
    let courseQuerier : CourseOutlineQuerier
    let videoController : OEXVideoPlayerInterface
    
    let loader = BackedStream<CourseBlock>()
    
    var rotateDeviceMessageView : IconMessageView?
    var contentView : UIView?
    var isHiddingNavBar: Bool = false
    
    let loadController : LoadStateViewController
    
    init(environment : Environment, blockID : CourseBlockID?, courseID: String) {
        self.blockID = blockID
        self.environment = environment
        courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID)
        videoController = OEXVideoPlayerInterface()
        loadController = LoadStateViewController()
        
        super.init(nibName: nil, bundle: nil)
        
        addChildViewController(videoController)
        videoController.didMoveToParentViewController(self)
        videoController.delegate = self
        addLoadListener()
    }
    
    var courseID : String {
        return courseQuerier.courseID
    }

    required init?(coder aDecoder: NSCoder) {
        // required by the compiler because UIViewController implements NSCoding,
        // but we don't actually want to serialize these things
        fatalError("init(coder:) has not been implemented")
    }
    
    func addLoadListener() {
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contentView = UIView(frame: CGRectZero)
        view.addSubview(contentView!)
        
        loadController.setupInController(self, contentView : contentView!)
        
        contentView!.addSubview(videoController.view)
        videoController.view.translatesAutoresizingMaskIntoConstraints = false
        videoController.fadeInOnLoad = false
        
        rotateDeviceMessageView = IconMessageView(icon: .RotateDevice, message: Strings.rotateDevice)
        contentView!.addSubview(rotateDeviceMessageView!)
        
        view.backgroundColor = OEXStyles.sharedStyles().standardBackgroundColor()
        view.setNeedsUpdateConstraints()
        
        videoController.hidesNextPrev = true
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.loadVideoIfNecessary()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)   
    }
    
    override func viewDidAppear(animated : Bool) {
        
        // if device in not landscape mode then change orientation to Portrait e.g when device on table in landscape mode then current orientation returns FaceUp and It's messes UI
        if UIDevice.currentDevice().orientation == .LandscapeLeft || UIDevice.currentDevice().orientation == .LandscapeRight {
            // nothing
        }
        else {
            UIDevice.currentDevice().setValue(UIInterfaceOrientation.Portrait.rawValue, forKey: "orientation")
        }
        
        // There's a weird OS bug where the bottom layout guide doesn't get set properly until
        // the layout cycle after viewDidAppear so cause a layout cycle
        self.view.setNeedsUpdateConstraints()
        self.view.updateConstraintsIfNeeded()
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        super.viewDidAppear(animated)
        
        guard canDownloadVideo() else {
            guard let video = self.environment.interface?.stateForVideoWithID(self.blockID, courseID : self.courseID) where video.downloadState == .Complete else {
                self.showOverlayMessage(Strings.noWifiMessage)
                return
            }
            
            return
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        showHideControls(false, animate: false)
        videoController.setAutoPlaying(false)
    }
    
    private func loadVideoIfNecessary() {
        if !loader.hasBacking {
            loader.backWithStream(courseQuerier.blockWithID(self.blockID).firstSuccess())
        }
    }
    
    override func updateViewConstraints() {
        
        switch UIDevice.currentDevice().orientation {
            case .Portrait, .FaceUp, .FaceDown :
            applyPortraitConstraints()
            case .LandscapeLeft, .LandscapeRight:
            applyLandscapeConstraints()
            default:
            applyPortraitConstraints()
        }
        
        super.updateViewConstraints()
    }
    
    private func applyPortraitConstraints() {
        
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
            
            make.height.equalTo(videoController.view.snp_width).multipliedBy(StandardVideoAspectRatio)
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
    }
    
    private func applyLandscapeConstraints() {
        
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
                make.top.equalTo(self.snp_bottomLayoutGuideBottom)
            }
            
            make.height.equalTo(videoController.view.snp_width)
        }
        
        rotateDeviceMessageView?.snp_updateConstraints {make in
            make.top.equalTo(videoController.view.snp_bottom)
            make.leading.equalTo(contentView!)
            make.trailing.equalTo(contentView!)
            make.height.equalTo(0.0)
            // There's a weird OS bug where the bottom layout guide doesn't get set properly until
            // the layout cycle after viewDidAppear, so use the parent in the mean time
            if #available(iOS 9, *) {
                make.bottom.equalTo(self.bottomLayoutGuide.topAnchor)
            }
            else {
                make.bottom.equalTo(self.snp_bottomLayoutGuideTop)
            }
        }
    }
    
    func movieTimedOut() {
        if videoController.moviePlayerController.fullscreen {
            UIAlertView(title: Strings.videoContentNotAvailable, message: "", delegate: nil, cancelButtonTitle: nil, otherButtonTitles: Strings.close).show()
        }
        else {
            self.showOverlayMessage(Strings.timeoutCheckInternetConnection)
        }
    }
    
    private func showError(error : NSError?) {
        loadController.state = LoadState.failed(error, icon: .UnknownError, message: Strings.videoContentNotAvailable)
    }
    
    private func showLoadedBlock(block : CourseBlock, forVideo video: OEXHelperVideoDownload?) {
        if let _ = block.type.asVideo {
            navigationItem.title = block.displayName
            
            dispatch_async(dispatch_get_main_queue()) {
                self.loadController.state = .Loaded
            }
            videoController.playVideoFor(video)
        }
        else {
            showError(nil)
        }
    }
    
    private func showHideControls(showhide: Bool , animate: Bool){
        navigationController?.setNavigationBarHidden(showhide, animated: animate)
        parentViewController?.navigationController?.setToolbarHidden(showhide, animated: animate)
    }
    
    private func canDownloadVideo() -> Bool {
        let hasWifi = environment.reachability.isReachableViaWiFi() ?? false
        let onlyOnWifi = environment.dataManager.interface?.shouldDownloadOnlyOnWifi ?? false
        return !onlyOnWifi || hasWifi
    }
    
    override func childViewControllerForStatusBarStyle() -> UIViewController? {
        return videoController
    }
    
    override func childViewControllerForStatusBarHidden() -> UIViewController? {
        return videoController
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        switch UIDevice.currentDevice().orientation {
        case .LandscapeLeft, .LandscapeRight: break
        default:
            let isHidden:Bool = (navigationController?.navigationBar.hidden)!

            if isHidden {
                showHideControls(false, animate: true)
            }
        }
        
        if videoController.moviePlayerController.fullscreen {
            videoController.moviePlayerController.setFullscreen(true, withOrientation: UIDevice.currentDevice().orientation)
            
        }
    }
    
    func videoPlayerTapped(sender: UIGestureRecognizer!) {
        
        switch UIDevice.currentDevice().orientation {
        case .LandscapeLeft, .LandscapeRight:
            let isHidden:Bool = (navigationController?.navigationBar.hidden)!
            
            if isHidden {
                isHiddingNavBar = false
            }
            else {
                isHiddingNavBar = true
            }
        default: break
        }
        
        showHideControls(isHiddingNavBar, animate: true)
    }
}
