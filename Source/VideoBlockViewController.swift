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

class VideoBlockViewController : OfflineSupportViewController, CourseBlockViewController, StatusBarOverriding, InterfaceOrientationOverriding, VideoTranscriptDelegate, RatingViewControllerDelegate, VideoPlayerDelegate {
    
    typealias Environment = DataManagerProvider & OEXInterfaceProvider & ReachabilityProvider & OEXConfigProvider & OEXRouterProvider & OEXAnalyticsProvider & OEXStylesProvider & OEXSessionProvider & NetworkManagerProvider
    
    let environment : Environment
    let blockID : CourseBlockID?
    let courseQuerier : CourseOutlineQuerier
    let videoPlayer: VideoPlayer
    let loader = BackedStream<CourseBlock>()
    var videoTranscriptView : VideoTranscript?
    var subtitleTimer = Timer()
    var contentView : UIView?
    let loadController : LoadStateViewController
    private var VOEnabledOnScreen = false
    var rotateDeviceMessageView : IconMessageView?
    private var video: OEXHelperVideoDownload?
    private let chromeCastManager = ChromeCastManager.shared
    private var chromeCastMiniPlayer: ChromeCastMiniPlayer?
    private var playOverlayButton: UIButton?
    private var overlayLabel: UILabel?
    
    init(environment : Environment, blockID : CourseBlockID?, courseID: String) {
        self.blockID = blockID
        self.environment = environment
        courseQuerier = environment.dataManager.courseDataManager.querierForCourseWithID(courseID: courseID, environment: environment)
        loadController = LoadStateViewController()
        let block = courseQuerier.blockWithID(id: blockID)
        if environment.config.youtubeVideoConfig.enabled && block.value?.type.asVideo?.isYoutubeVideo ?? false  {
            videoPlayer = YoutubeVideoPlayer(environment: environment)
        }
        else {
            videoPlayer = VideoPlayer(environment: environment)
        }
        super.init(env: environment)
        addChild(videoPlayer)
        videoPlayer.didMove(toParent: self)
        videoPlayer.playerDelegate = self
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
                        guard let video = self?.environment.interface?.stateForVideo(withID: self?.blockID, courseID : self?.courseID) else {
                            self?.showError(error: nil)
                            return
                        }
                        if video.summary?.isYoutubeVideo ?? false {
                            if self?.environment.config.youtubeVideoConfig.enabled ?? false {
                                self?.showLoadedBlock(block: block, forVideo: video)
                            }
                            else {
                                let url = block.blockURL
                                self?.showYoutubeMessage(url: url!)
                            }
                        }
                        else if block.type.asVideo?.preferredEncoding != nil {
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
        
        contentView?.addSubview(videoPlayer.view)
        videoPlayer.view.translatesAutoresizingMaskIntoConstraints = false
        rotateDeviceMessageView = IconMessageView(icon: .RotateDevice, message: Strings.rotateDevice)
        contentView?.addSubview(rotateDeviceMessageView!)
        let tapGesture = UITapGestureRecognizer()
        tapGesture.addAction {[weak self] _ in
            self?.videoPlayer.hideAndShowControls(isHidden: true)
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
        chromeCastManager.viewExpanded = false
    }
    
    private func configureChromecast() {
        guard let video = video else { return }
        if !chromeCastManager.isConnected || chromeCastMiniPlayer != nil { return }
        
        chromeCastMiniPlayer = ChromeCastMiniPlayer(environment: environment)
        let isYoutubeVideo = (video.summary?.isYoutubeVideo ?? true)
        guard let chromeCastMiniPlayer = chromeCastMiniPlayer, !isYoutubeVideo else { return }
        addChild(chromeCastMiniPlayer)
        contentView?.addSubview(chromeCastMiniPlayer.view)
        chromeCastMiniPlayer.didMove(toParent: self)
    }
    
    private func resetChromeCast() {
        for controller in children {
            if controller == chromeCastMiniPlayer {
                controller.willMove(toParent: nil)
                controller.view.removeFromSuperview()
                controller.removeFromParent()
            }
        }
        chromeCastManager.remove(delegate: self)
        removeOverlayMessage()
        removeChromeCastButton()
        chromeCastMiniPlayer = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !chromeCastManager.viewExpanded {
            resetChromeCast()
        }
    }
    
    override func viewDidAppear(_ animated : Bool) {
        
        // There's a weird OS bug where the bottom layout guide doesn't get set properly until
        // the layout cycle after viewDidAppear so cause a layout cycle
        view.setNeedsUpdateConstraints()
        view.updateConstraintsIfNeeded()
        view.setNeedsLayout()
        view.layoutIfNeeded()
        super.viewDidAppear(animated)
        
        if !chromeCastManager.viewExpanded {
            loadVideoIfNecessary()
        }
        chromeCastManager.add(delegate: self)
        chromeCastManager.viewExpanded = false
        
        if !chromeCastManager.isConnected && videoTranscriptView?.transcripts.count ?? 0 > 0 {
            validateSubtitleTimer()
        }
        
        if !(video?.summary?.isYoutubeVideo ?? true) {
            addChromeCastButton()
            showChromeCastOverlay()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        subtitleTimer.invalidate()
    }
    
    private func addChromeCastButton() {
        guard let parent = parent else { return }
        chromeCastManager.addChromeCastButton(over: parent)
    }
    
    private func removeChromeCastButton() {
        guard let parent = parent else { return }
        chromeCastManager.removeChromeCastButton(from: parent, force: true)
    }
    
    func setAccessibility() {
        if let ratingController = presentedViewController as? RatingViewController, UIAccessibility.isVoiceOverRunning {
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
        if let parentController = parent as? CourseContentPageViewController {
            if let ratingController = ratingController {
                parentController.setAccessibility(elements: ratingController.ratingContainerView.subviews, isShowingRating: true)
            }
            else {
                parentController.setAccessibility(elements: parentController.view.subviews)
            }
        }
    }
    
    private func loadVideoIfNecessary() {
        if let video = environment.interface?.stateForVideo(withID: blockID, courseID : courseID), loader.hasBacking {
            self.video = video
            play(video: video)
        }
        else if !loader.hasBacking {
            loader.backWithStream(courseQuerier.blockWithID(id: blockID).firstSuccess())
        }
    }
    
    private func updateControlsVisibility(hide: Bool) {
        rotateDeviceMessageView?.isHidden = hide
        videoTranscriptView?.transcriptTableView.isHidden = hide
        chromeCastManager.isMiniPlayerAdded = hide
        chromeCastMiniPlayer?.view.isHidden = !hide
    }
    
    private func cast(video: OEXHelperVideoDownload, time: TimeInterval? = nil) {
        addOverly(with: Strings.chromecastMessage)
        updateControlsVisibility(hide: true)
        videoPlayer.loadingIndicatorView.stopAnimating()
        videoPlayer.removeControls()
        configureChromecast()
        
        var playedTime: TimeInterval = 0.0
        if let time = time {
            playedTime = time
        }
        else {
            playedTime = TimeInterval(environment.interface?.lastPlayedInterval(forVideo: video) ?? 0)
        }
        chromeCastMiniPlayer?.play(video: video, time: playedTime)
    }
    
    private func playLocally(video: OEXHelperVideoDownload, time: TimeInterval? = nil) {
        updateControlsVisibility(hide: false)
        videoPlayer.play(video: video, time: time)
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
        guard let contentView = contentView else { return }
        contentView.snp.remakeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
        
        videoPlayer.view.snp.remakeConstraints { make in
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.top.equalTo(safeTop)
            make.height.equalTo(view.bounds.size.width * CGFloat(STANDARD_VIDEO_ASPECT_RATIO))
        }
        
        rotateDeviceMessageView?.snp.remakeConstraints { make in
            make.top.equalTo(videoPlayer.view.snp.bottom)
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.bottom.equalTo(safeBottom)
        }
        videoTranscriptView?.transcriptTableView.snp.remakeConstraints { make in
            make.top.equalTo(videoPlayer.view.snp.bottom)
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            let barHeight = navigationController?.toolbar.frame.size.height ?? 0.0
            make.bottom.equalTo(view.snp.bottom).offset(-barHeight)
        }
        
        setChromeCastPlayerConstraints()
    }
    
    private func applyLandscapeConstraints() {
        guard let contentView = contentView else { return }
        contentView.snp.remakeConstraints { make in
            make.edges.equalTo(safeEdges)
        }
        
        var playerHeight = view.bounds.size.height - (navigationController?.toolbar.bounds.height ?? 0)
        if chromeCastManager.isMiniPlayerAdded {
            playerHeight -= ChromeCastMiniPlayerHeight
        }
        
        videoPlayer.view.snp.remakeConstraints { make in
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.top.equalTo(safeTop)
            make.height.equalTo(playerHeight)
        }
        
        videoTranscriptView?.transcriptTableView.snp.remakeConstraints { make in
            make.top.equalTo(videoPlayer.view.snp.bottom)
            make.leading.equalTo(contentView)
            make.trailing.equalTo(contentView)
            make.bottom.equalTo(safeBottom)
        }
        
        rotateDeviceMessageView?.snp.remakeConstraints { make in
            make.height.equalTo(0.0)
        }
        
        setChromeCastPlayerConstraints()
    }
    
    private func setChromeCastPlayerConstraints() {
        chromeCastMiniPlayer?.view.snp.remakeConstraints { make in
            make.leading.equalTo(safeLeading)
            make.trailing.equalTo(safeTrailing)
            make.height.equalTo(ChromeCastMiniPlayerHeight)
            make.bottom.equalTo(safeBottom)
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
        self.video = video
        navigationItem.title = block.displayName
        videoPlayer.videoTitle = block.displayName
        DispatchQueue.main.async {[weak self] in
            self?.loadController.state = .Loaded
            self?.play(video: video)
        }
    }
    
    private func play(video: OEXHelperVideoDownload) {
        if chromeCastManager.isConnected && !(video.summary?.isYoutubeVideo ?? true) {
            cast(video: video)
        } else {
            playLocally(video: video)
        }
        environment.interface?.insertVideoData(video)
    }
    
    override var childForStatusBarStyle: UIViewController? {
        return videoPlayer
    }
    
    override var childForStatusBarHidden: UIViewController? {
        return videoPlayer
    }
    
    private func validateSubtitleTimer() {
        if !subtitleTimer.isValid {
            subtitleTimer = Timer.scheduledTimer(timeInterval: 1.0,
                                                 target: self,
                                                 selector: #selector(highlightSubtitle),
                                                 userInfo: nil,
                                                 repeats: true)
        }
    }
    
    @objc private func highlightSubtitle() {
        videoTranscriptView?.highlightSubtitle(for: videoPlayer.currentTime)
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        DispatchQueue.main.async {[weak self] in
            if let weakSelf = self {
                if weakSelf.chromeCastManager.isMiniPlayerAdded { return }
                
                if weakSelf.videoPlayer.isFullScreen {
                    if newCollection.verticalSizeClass == .regular {
                        weakSelf.videoPlayer.setFullscreen(fullscreen: false, animated: true, with: weakSelf.currentOrientation(), forceRotate: false)
                    }
                    else {
                        weakSelf.videoPlayer.setFullscreen(fullscreen: true, animated: true, with: weakSelf.currentOrientation(), forceRotate: false)
                    }
                }
                else if newCollection.verticalSizeClass == .compact {
                    weakSelf.videoPlayer.setFullscreen(fullscreen: true, animated: true, with: weakSelf.currentOrientation(), forceRotate: false)
                }
            }
        }
    }
    
    // willTransition only called in case of iPhone because iPhone has regular and compact vertical classes.
    // This method is specially for iPad
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        
        if videoPlayer.isFullScreen {
            videoPlayer.setFullscreen(fullscreen: !UIDevice.current.orientation.isPortrait, animated: true, with: currentOrientation(), forceRotate: false)
        }
        else if UIDevice.current.orientation.isLandscape {
            videoPlayer.setFullscreen(fullscreen: true, animated: true, with: currentOrientation(), forceRotate: false)
        }
    }
    
    //MARK: - VideoTranscriptDelegate methods
    func didSelectSubtitleAtInterval(time: TimeInterval) {
        videoPlayer.seek(to: time)
    }
    
    //MARK: - RatingDelegate
    func didDismissRatingViewController() {
        let after = DispatchTime.now() + Double(Int64(1.2 * TimeInterval(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: after) { [weak self] in
            self?.setAccessibility()
            //VO behave weirdly. If Rating view appears while VO is on then then VO consider it as screen otherwise it will treat as layout
            // Will revisit this logic when VO behaves same in all cases.
            self?.VOEnabledOnScreen ?? false ? UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged, argument: self?.navigationItem.backBarButtonItem) : UIAccessibility.post(notification: UIAccessibility.Notification.screenChanged, argument: self?.navigationItem.backBarButtonItem)
            
            self?.VOEnabledOnScreen = false
        }
    }
    
    override public var shouldAutorotate: Bool {
        return true
    }
    
    override public var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }
    
    //MARK: - VideoPlayerDelegate methods
    func playerWillMoveFromWindow(videoPlayer: VideoPlayer) {
        videoPlayer.view.snp.remakeConstraints { make in
            make.top.equalTo(safeTop)
            make.width.equalTo(view.bounds.size.width)
            make.height.equalTo(view.bounds.size.width * CGFloat(STANDARD_VIDEO_ASPECT_RATIO))
        }
    }
    
    func playerDidStopPlaying(videoPlayer: VideoPlayer, duration: Double, currentTime: Double) {
        if let video = environment.interface?.stateForVideo(withID: blockID, courseID : courseID) {
            environment.interface?.markLastPlayedInterval(Float(currentTime), forVideo: video)
            let state = doublesWithinEpsilon(left: duration, right: currentTime) ? OEXPlayedState.watched : OEXPlayedState.partiallyWatched
            environment.interface?.markVideoState(state, forVideo: video)
        }
    }
    
    func playerDidLoadTranscripts(videoPlayer:VideoPlayer, transcripts: [TranscriptObject]) {
        videoTranscriptView?.updateTranscript(transcript: transcripts)
        validateSubtitleTimer()
    }
    
    func playerDidFinishPlaying(videoPlayer: VideoPlayer) {
        environment.router?.showAppReviewIfNeeded(fromController: self)
        markVideoComplete()
    }
    
    func playerDidTimeout(videoPlayer: VideoPlayer) {
        if videoPlayer.isFullScreen {
            UIAlertController().showAlert(withTitle: Strings.timeoutCheckInternetConnection, message: "", cancelButtonTitle: Strings.close, onViewController: self)
        }
        else {
            addOverly(with: Strings.timeoutCheckInternetConnection)
        }
    }
    
    func playerDidFailedPlaying(videoPlayer: VideoPlayer, errorMessage: String) {
        if videoPlayer.isFullScreen {
            UIAlertController().showAlert(withTitle: errorMessage, message: "", cancelButtonTitle: Strings.close, onViewController: self)
        }
        else {
            addOverly(with: errorMessage)
        }
    }
    
    //MARK:- ChromeCastHelper
    
    private func showChromeCastOverlay() {
        // Introductory overlay needs reference to castButton which is available in CourseContentPageViewController,
        // This function calls before the castButton is initialized so we get x, y as 0 in its container,
        // We put a delay of 2 sec to get castButton from navigationbar item then decouple it and assgin to call.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            guard let parentController = self?.parent as? CourseContentPageViewController,
                let items = parentController.navigationItem.rightBarButtonItems else { return }
            self?.chromeCastManager.showIntroductoryOverlay(items: items)
        }
    }
    
    private func addOverly(with message: String) {
        if overlayLabel != nil { return }
        removeOverlayPlayButton()
        overlayLabel = UILabel()
        overlayLabel?.numberOfLines = 0
        guard let overlayLabel = overlayLabel else { return }
        view.addSubview(overlayLabel)
        let style = OEXTextStyle(weight: .normal, size: .large, color: .white)
        overlayLabel.attributedText = style.attributedString(withText: message)
        
        overlayLabel.snp.makeConstraints({ (make) in
            make.center.equalTo(videoPlayer.view)
        })
    }
    
    private func removeOverlayMessage() {
        chromeCastMiniPlayer?.view.isHidden = true
        overlayLabel?.text = ""
        overlayLabel?.isHidden = true
        overlayLabel?.removeFromSuperview()
        overlayLabel = nil
    }
    
    func createOverlayPlayButton() {
        if playOverlayButton != nil { return }
        chromeCastManager.isMiniPlayerAdded = false
        removeOverlayMessage()
        playOverlayButton = UIButton()
        playOverlayButton?.tintColor = .white
        playOverlayButton?.setImage(UIImage.PlayIcon(), for: .normal)
        playOverlayButton?.oex_addAction({ [weak self] _ in
            self?.playButtonAction()
        }, for: .touchUpInside)
        guard let playOverlayButton = playOverlayButton else { return }
        view.addSubview(playOverlayButton)
        playOverlayButton.snp.makeConstraints { make in
            make.center.equalTo(videoPlayer.view)
            make.height.equalTo(26)
            make.width.equalTo(26)
        }
    }
    
    @objc func playButtonAction() {
        removeOverlayPlayButton()
        loadVideoIfNecessary()
    }
    
    private func removeOverlayPlayButton() {
        playOverlayButton?.isHidden = true
        playOverlayButton?.removeFromSuperview()
        playOverlayButton = nil
    }

    @objc override func reloadViewData() {
        removeOverlayMessage()
        loadVideoIfNecessary()
    }
}

extension VideoBlockViewController {
    func markVideoComplete() {
        guard let username = environment.session.currentUser?.username, let blockID = blockID else { return }
        let networkRequest = VideoCompletionApi.videoCompletion(username: username, courseID: courseID, blockID: blockID)
        environment.networkManager.taskForRequest(networkRequest) { _ in }
    }
}

//MARK:- ChromeCastPlayerStatusDelegate

extension VideoBlockViewController: ChromeCastPlayerStatusDelegate {
    func chromeCastDidConnect() {
        if videoPlayer.isFullScreen {
            videoPlayer.setFullscreen(fullscreen: false, animated: true, with: currentOrientation(), forceRotate: false)
        }
        let time = videoPlayer.currentTime
        videoPlayer.resetPlayer()
        
        guard let video = video else {
            loadVideoIfNecessary()
            return
        }
        
        cast(video: video, time: time)
    }
    
    func chromeCastDidDisconnect(playedTime: TimeInterval) {
        removeOverlayMessage()
        removeOverlayPlayButton()
        guard let video = video else {
            loadVideoIfNecessary()
            return
        }
        playLocally(video: video, time: playedTime)
    }
    
    func chromeCastVideoPlaying() {

    }
    
    func chromeCastDidFinishPlaying() {
        createOverlayPlayButton()
        videoPlayer.savePlayedTime(time: .zero)
    }
}
