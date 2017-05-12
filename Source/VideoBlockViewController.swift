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

class VideoBlockViewController : UIViewController, CourseBlockViewController, OEXVideoPlayerInterfaceDelegate, StatusBarOverriding, InterfaceOrientationOverriding, VideoTranscriptDelegate, RatingViewControllerDelegate {
    
    typealias Environment = DataManagerProvider & OEXInterfaceProvider & ReachabilityProvider & OEXConfigProvider & OEXRouterProvider

    let environment : Environment
    let blockID : CourseBlockID?
    let courseQuerier : CourseOutlineQuerier
    let videoController : OEXVideoPlayerInterface
    
    let loader = BackedStream<CourseBlock>()
    
    var rotateDeviceMessageView : IconMessageView?
    var videoTranscriptView : VideoTranscript?
    var subtitleTimer = Timer()
    var contentView : UIView?
    let loadController : LoadStateViewController
    private var VOEnabledOnScreen = false
    
    init(environment : Environment, blockID : CourseBlockID?, courseID: String) {
        self.blockID = blockID
        self.environment = environment
        courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID: courseID)
        videoController = OEXVideoPlayerInterface()
        loadController = LoadStateViewController()
        
        super.init(nibName: nil, bundle: nil)
        
        addChildViewController(videoController)
        videoController.didMove(toParentViewController: self)
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
                        if let video = block.type.asVideo, video.isYoutubeVideo,
                            let url = block.blockURL
                        {
                            self?.showYoutubeMessage(url: url)
                        }
                        else if
                            let video = self?.environment.interface?.stateForVideo(withID: self?.blockID, courseID : self?.courseID), block.type.asVideo?.preferredEncoding != nil
                        {
                            self?.showLoadedBlock(block: block, forVideo: video)
                        }
                        else {
                            self?.showError(error: nil)
                        }
            }, failure : {[weak self] error in
                self?.showError(error: error)
            }
        )
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        contentView = UIView(frame: CGRect.zero)
        view.addSubview(contentView!)
        
        loadController.setupInController(controller: self, contentView : contentView!)
        
        contentView?.addSubview(videoController.view)
        videoController.view.translatesAutoresizingMaskIntoConstraints = false
        videoController.fadeInOnLoad = false
        
        rotateDeviceMessageView = IconMessageView(icon: .RotateDevice, message: Strings.rotateDevice)
        contentView?.addSubview(rotateDeviceMessageView!)
        
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addAction {[weak self] _ in
            self?.videoController.moviePlayerController?.controls?.hideOptionsAndValues()
        }
        rotateDeviceMessageView?.addGestureRecognizer(tapGesture)

        if environment.config.isVideoTranscriptEnabled {
            videoTranscriptView = VideoTranscript(environment: environment)
            videoTranscriptView?.delegate = self
            contentView?.addSubview(videoTranscriptView!.transcriptTableView)
        }
        
        view.backgroundColor = OEXStyles.shared().standardBackgroundColor()
        view.setNeedsUpdateConstraints()
        
        NotificationCenter.default.oex_addObserver(observer: self, name: UIAccessibilityVoiceOverStatusChanged) { (_, observer, _) in
            observer.setAccessibility()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.loadVideoIfNecessary()
    }
    
    override func viewDidAppear(_ animated : Bool) {
        
        // There's a weird OS bug where the bottom layout guide doesn't get set properly until
        // the layout cycle after viewDidAppear so cause a layout cycle
        self.view.setNeedsUpdateConstraints()
        self.view.updateConstraintsIfNeeded()
        self.view.setNeedsLayout()
        self.view.layoutIfNeeded()
        super.viewDidAppear(animated)
        
        validateSubtitleTimer()
        
        if !canDownloadVideo() {
            guard let video = self.environment.interface?.stateForVideo(withID: self.blockID, courseID : self.courseID), video.downloadState == .complete else {
                self.showOverlay(withMessage: Strings.noWifiMessage)
                return
            }
        }
        
        guard let videoPlayer = videoController.moviePlayerController else { return }
        if currentOrientation() == .landscapeLeft || currentOrientation() == .landscapeRight {
            videoPlayer.setFullscreen(true, with: self.currentOrientation())
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        videoController.setAutoPlaying(false)
        self.subtitleTimer.invalidate()
    }
    
    func setAccessibility() {
        if let ratingController = self.presentedViewController as? RatingViewController, UIAccessibilityIsVoiceOverRunning() {
            // If Timely App Reviews popup is showing then set popup elements as accessibilityElements
            view.accessibilityElements = [ratingController.ratingContainerView.subviews]
            setParentAccessibility(ratingController: ratingController)
            VOEnabledOnScreen = true
        }
        else {
            view.accessibilityElements = [view.subviews]
            setParentAccessibility()
        }
    }

    func setParentAccessibility(ratingController: RatingViewController? = nil) {
        if let parentController = self.parent as? CourseContentPageViewController {
            if let ratingController = ratingController {
                parentController.setAccessibility(elements: ratingController.ratingContainerView.subviews, isShowingRating: true)
            }
            else {
                parentController.setAccessibility(elements: parentController.view.subviews)
            }
        }
    }

    private func loadVideoIfNecessary() {
        if !loader.hasBacking {
            loader.backWithStream(courseQuerier.blockWithID(id: self.blockID).firstSuccess())
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateViewConstraints()
    }
    
    override func updateViewConstraints() {
        
        if  self.isVerticallyCompact() {
            applyLandscapeConstraints()
        }
        else{
            applyPortraitConstraints()
        }
        
        super.updateViewConstraints()
    }
    
    private func applyPortraitConstraints() {
        
        contentView?.snp_remakeConstraints {make in
            make.edges.equalTo(view)
        }
        
        videoController.height = view.bounds.size.width * CGFloat(STANDARD_VIDEO_ASPECT_RATIO)
        videoController.width = view.bounds.size.width
        
        videoController.view.snp_remakeConstraints {make in
            make.leading.equalTo(contentView!)
            make.trailing.equalTo(contentView!)
            make.top.equalTo(self.snp_topLayoutGuideBottom)
            make.height.equalTo(view.bounds.size.width * CGFloat(STANDARD_VIDEO_ASPECT_RATIO))
        }
        
        rotateDeviceMessageView?.snp_remakeConstraints {make in
            make.top.equalTo(videoController.view.snp_bottom)
            make.leading.equalTo(contentView!)
            make.trailing.equalTo(contentView!)
            make.bottom.equalTo(self.snp_bottomLayoutGuideTop)
        }
        
        videoTranscriptView?.transcriptTableView.snp_remakeConstraints { make in
            make.top.equalTo(videoController.view.snp_bottom)
            make.leading.equalTo(contentView!)
            make.trailing.equalTo(contentView!)
            let barHeight = navigationController?.toolbar.frame.size.height ?? 0.0
            make.bottom.equalTo(view.snp_bottom).offset(-barHeight)
            }
    }
    
    private func applyLandscapeConstraints() {
        
        contentView?.snp_remakeConstraints {make in
            make.edges.equalTo(view)
        }
        
        let playerHeight = view.bounds.size.height - (navigationController?.toolbar.bounds.height ?? 0)
        
        videoController.height = playerHeight
        videoController.width = view.bounds.size.width
        
        videoController.view.snp_remakeConstraints {make in
            make.leading.equalTo(contentView!)
            make.trailing.equalTo(contentView!)
            make.top.equalTo(self.snp_topLayoutGuideBottom)
            make.height.equalTo(playerHeight)
        }
        
        rotateDeviceMessageView?.snp_remakeConstraints {make in
            make.height.equalTo(0.0)
        }
    }
    
    func movieTimedOut() {
        if let controller = videoController.moviePlayerController, controller.isFullscreen {
            UIAlertView(title: Strings.videoContentNotAvailable, message: "", delegate: nil, cancelButtonTitle: nil, otherButtonTitles: Strings.close).show()
        }
        else {
            self.showOverlay(withMessage: Strings.timeoutCheckInternetConnection)
        }
    }
    
    private func showError(error : NSError?) {
        loadController.state = LoadState.failed(error: error, icon: .UnknownError, message: Strings.videoContentNotAvailable)
    }
    
    private func showYoutubeMessage(url: NSURL) {
        let buttonInfo = MessageButtonInfo(title: Strings.Video.viewOnYoutube) {
            if UIApplication.shared.canOpenURL(url as URL){
                UIApplication.shared.openURL(url as URL)
            }
        }
        loadController.state = LoadState.empty(icon: .CourseModeVideo, message: Strings.Video.onlyOnYoutube, attributedMessage: nil, accessibilityMessage: nil, buttonInfo: buttonInfo)
    }
    
    private func showLoadedBlock(block : CourseBlock, forVideo video: OEXHelperVideoDownload) {
        navigationItem.title = block.displayName
        
        DispatchQueue.main.async {
            self.loadController.state = .Loaded
        }
        
        videoController.playVideo(for: video)
    }
    
    private func canDownloadVideo() -> Bool {
        let hasWifi = environment.reachability.isReachableViaWiFi() 
        let onlyOnWifi = environment.dataManager.interface?.shouldDownloadOnlyOnWifi ?? false
        return !onlyOnWifi || hasWifi
    }
    
    override var childViewControllerForStatusBarStyle: UIViewController? {
        return videoController
    }
    
    override var childViewControllerForStatusBarHidden: UIViewController? {
        return videoController
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        guard let videoPlayer = videoController.moviePlayerController else { return }
        
        if videoPlayer.isFullscreen {
            
            if newCollection.verticalSizeClass == .regular {
                videoPlayer.setFullscreen(false, with: self.currentOrientation())
            }
            else {
                videoPlayer.setFullscreen(true, with: self.currentOrientation())
            }
        }
        else if videoController.shouldRotate && newCollection.verticalSizeClass == .compact {
            videoPlayer.setFullscreen(true, with: self.currentOrientation())
        }

    }
    
    func validateSubtitleTimer() {
        if !subtitleTimer.isValid && videoController.moviePlayerController?.controls != nil {
            subtitleTimer = Timer.scheduledTimer(timeInterval: 1.0,
                                                                   target: self,
                                                                   selector: #selector(highlightSubtitle),
                                                                   userInfo: nil,
                                                                   repeats: true)
        }
    }
    
    func highlightSubtitle() {
        videoTranscriptView?.highlightSubtitleForTime(time: videoController.moviePlayerController?.controls?.moviePlayer?.currentPlaybackTime)
    }
    
    //MARK: - OEXVideoPlayerInterfaceDelegate methods
    func videoPlayerTapped(_ sender: UIGestureRecognizer) {
        guard let videoPlayer = videoController.moviePlayerController else { return }
        
        if self.isVerticallyCompact() && !videoPlayer.isFullscreen{
            videoPlayer.setFullscreen(true, with: currentOrientation())
        }
    }
    
    func transcriptLoaded(_ transcript: [Any]) {
        videoTranscriptView?.updateTranscript(transcript: transcript as [AnyObject])
        validateSubtitleTimer()
    }
    
    func didFinishVideoPlaying() {
        environment.router?.showAppReviewIfNeeded(fromController: self)
    }
    
    //MARK: - VideoTranscriptDelegate methods
    func didSelectSubtitleAtInterval(time: TimeInterval) {
        self.videoController.moviePlayerController?.controls?.hideOptionsAndValues()
        videoController.moviePlayerController?.controls?.setCurrentPlaybackTimeFromTranscript(time)
    }
    
    //MARK: - RatingDelegate
    func didDismissRatingViewController() {
        let after = DispatchTime.now() + Double(Int64(1.2 * TimeInterval(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: after) { [weak self] in
            self?.setAccessibility()
            //VO behave weirdly. If Rating view appears while VO is on then then VO consider it as screen otherwise it will treat as layout
            // Will revisit this logic when VO behaves same in all cases.
            self?.VOEnabledOnScreen ?? false ? UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, self?.navigationItem.backBarButtonItem) : UIAccessibilityPostNotification(UIAccessibilityScreenChangedNotification, self?.navigationItem.backBarButtonItem)
            
            self?.VOEnabledOnScreen = false
        }
    }
}
