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

class VideoBlockViewController : UIViewController, CourseBlockViewController, StatusBarOverriding, InterfaceOrientationOverriding, VideoTranscriptDelegate, RatingViewControllerDelegate, VideoPlayerControllerDelegate {
    
    typealias Environment = DataManagerProvider & OEXInterfaceProvider & ReachabilityProvider & OEXConfigProvider & OEXRouterProvider

    let environment : Environment
    let blockID : CourseBlockID?
    let courseQuerier : CourseOutlineQuerier
    let videoController = AVVideoPlayer()
    let loader = BackedStream<CourseBlock>()
    var videoTranscriptView : VideoTranscript?
    var subtitleTimer = Timer()
    var contentView : UIView?
    let loadController : LoadStateViewController
    private var VOEnabledOnScreen = false
    var currentVideo : OEXHelperVideoDownload?
    
    init(environment : Environment, blockID : CourseBlockID?, courseID: String) {
        self.blockID = blockID
        self.environment = environment
        courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID: courseID)
        loadController = LoadStateViewController()
        super.init(nibName: nil, bundle: nil)
        addChildViewController(videoController)
        videoController.didMove(toParentViewController: self)
        videoController.playerDelegate = self
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
        loadVideoIfNecessary()
    }
    
    override func viewDidAppear(_ animated : Bool) {
        
        // There's a weird OS bug where the bottom layout guide doesn't get set properly until
        // the layout cycle after viewDidAppear so cause a layout cycle
        view.setNeedsUpdateConstraints()
        view.updateConstraintsIfNeeded()
        view.setNeedsLayout()
        view.layoutIfNeeded()
        super.viewDidAppear(animated)
        
        if !(environment.interface?.canDownload() ?? false) {
            guard let video = environment.interface?.stateForVideo(withID: blockID, courseID : courseID), video.downloadState == .complete else {
                showOverlay(withMessage: environment.interface?.networkErrorMessage() ?? Strings.noWifiMessage)
                return
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        subtitleTimer.invalidate()
    }
    
    func setAccessibility() {
        if let ratingController = presentedViewController as? RatingViewController, UIAccessibilityIsVoiceOverRunning() {
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
            loader.backWithStream(courseQuerier.blockWithID(id: blockID).firstSuccess())
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateViewConstraints()
    }
    
    override func updateViewConstraints() {
        if  isVerticallyCompact() {
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
        
        videoController.height = Double(view.bounds.size.width * CGFloat(STANDARD_VIDEO_ASPECT_RATIO))
        videoController.width = Double(view.bounds.size.width)
        
        videoController.view.snp_remakeConstraints {make in
            make.leading.equalTo(contentView!)
            make.trailing.equalTo(contentView!)
            make.top.equalTo(snp_topLayoutGuideBottom)
            make.height.equalTo(view.bounds.size.width * CGFloat(STANDARD_VIDEO_ASPECT_RATIO))
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
        videoController.height = Double(playerHeight)
        videoController.width = Double(view.bounds.size.width)
        
        videoController.view.snp_remakeConstraints {make in
            make.leading.equalTo(contentView!)
            make.trailing.equalTo(contentView!)
            make.top.equalTo(snp_topLayoutGuideBottom)
            make.height.equalTo(playerHeight)
        }
        
        videoTranscriptView?.transcriptTableView.snp_remakeConstraints { make in
            make.top.equalTo(videoController.view.snp_bottom)
            make.leading.equalTo(contentView!)
            make.trailing.equalTo(contentView!)
            make.bottom.equalTo(view)
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
        loadController.state = LoadState.empty(icon: .CourseVideos, message: Strings.Video.onlyOnYoutube, attributedMessage: nil, accessibilityMessage: nil, buttonInfo: buttonInfo)
    }
    
    private func showLoadedBlock(block : CourseBlock, forVideo video: OEXHelperVideoDownload) {
        navigationItem.title = block.displayName
        DispatchQueue.main.async {[weak self] _ in
            self?.loadController.state = .Loaded
        }
        playVideo(video: video)
    }
    
    private func playVideo(video : OEXHelperVideoDownload) {
        videoController.playerControls?.video = video
        videoController.video = video
        currentVideo = video
        if let videoURL = video.summary?.videoURL {
            var url : URL? = URL(string:videoURL)
            let fileManager = FileManager.default
            let path = "\(video.filePath).mp4"
            let fileExists : Bool = fileManager.fileExists(atPath: path)
            if fileExists {
                url = URL(fileURLWithPath: path)
            }
            if video.downloadState == .complete && !fileExists {
                return
            }
            videoController.contentURL = url
            let timeInterval = TimeInterval(OEXInterface.shared().lastPlayedInterval(forVideo: video))
            if timeInterval > 0.0 {
                videoController.play(at: timeInterval)
            }
            else {
                videoController.play()
            }
        }
    }
    
    override var childViewControllerForStatusBarStyle: UIViewController? {
        return videoController
    }
    
    override var childViewControllerForStatusBarHidden: UIViewController? {
        return videoController
    }
    
    private func validateSubtitleTimer() {
        if !subtitleTimer.isValid && videoController.playerControls != nil {
            subtitleTimer = Timer.scheduledTimer(timeInterval: 1.0,
                                                 target: self,
                                                 selector: #selector(highlightSubtitle),
                                                 userInfo: nil,
                                                 repeats: true)
        }
    }
    
    @objc private func highlightSubtitle() {
        videoTranscriptView?.highlightSubtitle(for: videoController.currentTime)
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        //guard let videoPlayer = videoController.moviePlayerController else { return }
        
        if videoController.movieFullscreen {

            if newCollection.verticalSizeClass == .regular {
                videoController.setFullscreen(fullscreen: false, animated: true, with: currentOrientation(), forceRotate: false)
            }
            else {
                videoController.setFullscreen(fullscreen: true, animated: true, with: currentOrientation(), forceRotate: false)
            }
        }
        else if newCollection.verticalSizeClass == .compact {
            videoController.setFullscreen(fullscreen: true, animated: true, with: currentOrientation(), forceRotate: false)
        }
    }
    
    // willTransition only called in case of iPhone because iPhone has regular and compact vertical classes.
    // This method is specially for iPad
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        
        if videoController.movieFullscreen {
            videoController.setFullscreen(fullscreen: !UIDevice.current.orientation.isPortrait, animated: true, with: currentOrientation(), forceRotate: false)
        }
        else if UIDevice.current.orientation.isLandscape {
             videoController.setFullscreen(fullscreen: true, animated: true, with: currentOrientation(), forceRotate: false)
        }
    }

    //MARK: - VideoTranscriptDelegate methods
    func didSelectSubtitleAtInterval(time: TimeInterval) {
        videoController.resume(at: time)
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
    
    override public var shouldAutorotate: Bool {
        return true
    }
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    //MARK: - VideoPlayerControllerDelegate methods
    func moviePlayerWillMoveFromWindow() {
        videoController.view.snp_updateConstraints { make in
            make.width.equalTo(view.bounds.size.width)
            make.height.equalTo(view.bounds.size.width * CGFloat(STANDARD_VIDEO_ASPECT_RATIO))
        }
    }

    func playerDidStopPlaying(duration: Double, currentTime: Double) {
        if let currentVideo = currentVideo {
            OEXInterface.shared().markLastPlayedInterval(Float(currentTime), forVideo: currentVideo)
            let state = doublesWithinEpsilon(left: duration, right: currentTime) ? OEXPlayedState.watched : OEXPlayedState.partiallyWatched
            OEXInterface.shared().markVideoState(state, forVideo: currentVideo)
        }
    }
    
    func transcriptLoaded(transcripts: [SubTitle]) {
        videoTranscriptView?.updateTranscript(transcript: transcripts)
        validateSubtitleTimer()
    }
    
    func didFinishVideoPlaying() {
        environment.router?.showAppReviewIfNeeded(fromController: self)
    }
    
    func movieTimedOut() {
        if videoController.movieFullscreen {
            UIAlertView(title: Strings.timeoutCheckInternetConnection, message: "", delegate: nil, cancelButtonTitle: nil, otherButtonTitles: Strings.close).show()
        }
        else {
            showOverlay(withMessage: Strings.timeoutCheckInternetConnection)
        }
    }
}
