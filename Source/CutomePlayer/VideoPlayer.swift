
//
//  VideoPlayer.swift
//  edX
//
//  Created by Salman on 05/03/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit
import AVKit

private enum PlayerState {
    case playing,
    paused,
    stoped
}

private let currentItemStatusKey = "currentItem.status"
private let currentItemPlaybackLikelyToKeepUpKey = "currentItem.playbackLikelyToKeepUp"

protocol VideoPlayerDelegate: class {
    func playerDidLoadTranscripts(videoPlayer:VideoPlayer, transcripts: [TranscriptObject])
    func playerWillMoveFromWindow(videoPlayer: VideoPlayer)
    func playerDidTimeout(videoPlayer: VideoPlayer)
    func playerDidFinishPlaying(videoPlayer: VideoPlayer)
    func playerDidFailedPlaying(videoPlayer: VideoPlayer, errorMessage: String)
}

private var playbackLikelyToKeepUpContext = 0
class VideoPlayer: UIViewController,VideoPlayerControlsDelegate,TranscriptManagerDelegate {
    
    typealias Environment = OEXInterfaceProvider & OEXAnalyticsProvider & OEXStylesProvider
    
    public let environment : Environment
    fileprivate var controls: VideoPlayerControls?
    weak var playerDelegate : VideoPlayerDelegate?
    var isFullScreen : Bool = false {
        didSet {
            controls?.updateFullScreenButtonImage()
        }
    }
    fileprivate let playerView = PlayerView()
    private var timeObserver : AnyObject?
    fileprivate let player = AVPlayer()
    let loadingIndicatorView = UIActivityIndicatorView(style: .white)
    private var lastElapsedTime: TimeInterval = 0
    private var transcriptManager: TranscriptManager?
    let videoSkipBackwardsDuration: Double = 10
    let videoSkipForwardsDuration: Double = 15
    private var playerTimeBeforeSeek:TimeInterval = 0
    private var playerState: PlayerState = .stoped
    private var isObserverAdded: Bool = false
    private let playerTimeOutInterval:TimeInterval = 60.0
    private let preferredTimescale:Int32 = 100
    fileprivate var fullScreenContainerView: UIView?
    
    // UIPageViewController keep multiple viewControllers simultanously for smooth switching
    // on view transitioning this method calls for every viewController which cause framing issue for fullscreen mode
    // as we are using rootViewController of keyWindow for fullscreen mode.
    // We introduce the variable isVisible to track the visible viewController during pagination.
    fileprivate var isVisible: Bool = false
    
    var videoTitle: String = Strings.untitled
    
    private let loadingIndicatorViewSize = CGSize(width: 50.0, height: 50.0)
    
    public var video: OEXHelperVideoDownload? {
        didSet {
            initializeSubtitles()
        }
    }
    
    lazy fileprivate var movieBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.alpha = 0.5
        return view
    }()
    
    var rate: Float {
        get {
            return player.rate
        }
        set {
            player.rate = newValue
        }
    }
    
    var duration: CMTime {
        return player.currentItem?.duration ?? CMTime()
    }
    
    var isPlaying: Bool {
        return rate != 0
    }
    
    var currentTime: TimeInterval {
        return player.currentItem?.currentTime().seconds ?? 0
    }
    
    var playableDuration: TimeInterval {
        var result: TimeInterval = 0
        if let loadedTimeRanges = player.currentItem?.loadedTimeRanges, loadedTimeRanges.count > 0  {
            let timeRange = loadedTimeRanges[0].timeRangeValue
            let startSeconds: Float64 = CMTimeGetSeconds(timeRange.start)
            let durationSeconds: Float64 = CMTimeGetSeconds(timeRange.duration)
            result =  TimeInterval(startSeconds) + TimeInterval(durationSeconds)
        }
        return result
    }
    
    private lazy var leftSwipeGestureRecognizer : UISwipeGestureRecognizer = {
        let gesture = UISwipeGestureRecognizer()
        gesture.direction = .left
        gesture.addAction { [weak self] _ in
            self?.controls?.nextButtonClicked()
        }
        
        return gesture
    }()
    
    private lazy var rightSwipeGestureRecognizer : UISwipeGestureRecognizer = {
        let gesture = UISwipeGestureRecognizer()
        gesture.direction = .right
        gesture.addAction { [weak self] _ in
            self?.controls?.previousButtonClicked()
        }
        
        return gesture
    }()
    
    private lazy var pinchGestureRecognizer : UIPinchGestureRecognizer = {
        let gesture = UIPinchGestureRecognizer()
        gesture.addAction { [weak self] _ in
            self?.zoomInOutVideo(sender: gesture)
        }
        
        return gesture
    }()
    
    // Adding this accessibilityPlayerView for the player accessibility voice over
    private let accessibilityPlayerView : UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        
        return view
    }()
    
    init(environment : Environment) {
        self.environment = environment
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createPlayer()
        view.backgroundColor = .black
        loadingIndicatorView.hidesWhenStopped = true
    }
    
    @objc func zoomInOutVideo(sender: UIPinchGestureRecognizer) {
        if isVerticallyCompact() {
            let size = (sender.velocity > 0 ? 1 : -1)
            if size == 1 {
                playerView.playerLayer.videoGravity = .resizeAspectFill
            }
            else {
                playerView.playerLayer.videoGravity = .resizeAspect
            }
        }
    }
    
    private func addObservers() {
        if !isObserverAdded {
            isObserverAdded = true
            player.addObserver(self, forKeyPath: currentItemPlaybackLikelyToKeepUpKey,
                               options: .new, context: &playbackLikelyToKeepUpContext)
            
            
            player.addObserver(self, forKeyPath: currentItemStatusKey,
                               options: .new, context: nil)
            
            let timeInterval: CMTime = CMTimeMakeWithSeconds(1.0, preferredTimescale: 10)
            timeObserver = player.addPeriodicTimeObserver(forInterval: timeInterval, queue: DispatchQueue.main) { [weak self]
                (elapsedTime: CMTime) -> Void in
                self?.observeProgress(elapsedTime: elapsedTime)
                } as AnyObject
            
            NotificationCenter.default.oex_addObserver(observer: self, name: UIApplication.willResignActiveNotification.rawValue) {(notification, observer, _) in
                observer.pause()
                observer.controls?.setPlayPauseButtonState(isSelected: true)
            }
            
            NotificationCenter.default.oex_addObserver(observer: self, name: UIAccessibilityVoiceOverStatusChanged, action: { (_, observer, _) in
                observer.voiceOverStatusChanged()
            })
        }
    }
    
    private func voiceOverStatusChanged() {
        hideAndShowControls(isHidden: !UIAccessibility.isVoiceOverRunning)
    }
    
    private func observeProgress(elapsedTime: CMTime) {
        let duration = CMTimeGetSeconds(self.duration)
        if duration.isFinite {
            let elapsedTime = CMTimeGetSeconds(elapsedTime)
            controls?.durationSliderValue = Float(elapsedTime / duration)
            controls?.updateTimeLabel(elapsedTime: elapsedTime, duration: duration)
        }
    }
    
    private func createPlayer() {
        view.addSubview(playerView)
        
        // Adding this accessibilityPlayerView just for the accibility voice over
        playerView.addSubview(accessibilityPlayerView)
        accessibilityPlayerView.isAccessibilityElement = true
        accessibilityPlayerView.accessibilityLabel = Strings.accessibilityVideo
        
        playerView.playerLayer.player = player
        view.layer.insertSublayer(playerView.playerLayer, at: 0)
        playerView.addSubview(loadingIndicatorView)
        
        if #available(iOS 10.0, *) {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.defaultToSpeaker])
        } else {
            // Fallback on earlier versions
            // Workaround until https://forums.swift.org/t/using-methods-marked-unavailable-in-swift-4-2/14949 isn't fixed
            AVAudioSession.sharedInstance().perform(NSSelectorFromString("setCategory:error:"), with: AVAudioSession.Category.playback)
            
        }
        setConstraints()
    }
    
    func createControls() {
        if controls != nil { return }
        controls = VideoPlayerControls(environment: environment, player: self)
        controls?.delegate = self
        if let controls = controls {
            playerView.addSubview(controls)
        }
        controls?.snp.makeConstraints() { make in
            make.edges.equalTo(playerView)
        }
    }
    
    func removeControls() {
        controls?.removeFromSuperview()
        controls = nil
    }
    
    private func initializeSubtitles() {
        if let video = video, transcriptManager == nil {
            transcriptManager = TranscriptManager(environment: environment, video: video)
            transcriptManager?.delegate = self
            
            if let ccSelectedLanguage = OEXInterface.getCCSelectedLanguage(), let transcriptURL = video.summary?.transcripts?[ccSelectedLanguage] as? String, !ccSelectedLanguage.isEmpty, !transcriptURL.isEmpty {
                controls?.activateSubTitles()
            }
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if !isFullScreen && !isVerticallyCompact() {
            playerView.frame = view.bounds
        } else {
            playerView.frame = movieBackgroundView.bounds
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &playbackLikelyToKeepUpContext, let currentItem = player.currentItem {
            if currentItem.isPlaybackLikelyToKeepUp {
                loadingIndicatorView.stopAnimating()
            } else {
                loadingIndicatorView.startAnimating()
            }
        }
        else if keyPath == currentItemStatusKey {
            if let newStatusAsNumber = change?[NSKeyValueChangeKey.newKey] as? NSNumber, let newStatus = AVPlayerItem.Status(rawValue: newStatusAsNumber.intValue) {
                switch newStatus {
                case .readyToPlay:
                    //This notification call specifically for test cases in readyToPlay state
                    perform(#selector(t_postNotification))
                    
                    NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(movieTimedOut), object: nil)
                    controls?.isTapButtonHidden = false
                    break
                case .unknown:
                    controls?.isTapButtonHidden = true
                    break
                case .failed:
                    controls?.isTapButtonHidden = true
                    break
                @unknown default:
                    break
                }
            }
        }
    }
    
    private func setConstraints() {
        loadingIndicatorView.snp.makeConstraints() { make in
            make.center.equalToSuperview()
            make.height.equalTo(loadingIndicatorViewSize.height)
            make.width.equalTo(loadingIndicatorViewSize.width)
        }
        
        accessibilityPlayerView.snp.makeConstraints { make in
            make.edges.equalTo(playerView)
        }
    }
    
    private func updatePlayerConstrainsts(target: ConstraintRelatableTarget) {
        playerView.snp.remakeConstraints { make in
            make.edges.equalTo(target)
        }
        
        controls?.snp.remakeConstraints() { make in
            make.edges.equalTo(target)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isVisible = true
        if !ChromeCastManager.shared.isMiniPlayerAdded {
            applyScreenOrientation()
        }
        resume()
    }
    
    private func applyScreenOrientation() {
        if isVerticallyCompact() {
            DispatchQueue.main.async {[weak self] in
                self?.setFullscreen(fullscreen: true, animated: false, with: .portrait, forceRotate: false)
            }
        }
    }
    
    func play(video: OEXHelperVideoDownload, time: TimeInterval? = nil) {
        guard let videoURL = video.summary?.videoURL, var url = URL(string: videoURL) else {
            return
        }
        createControls()
        self.video = video
        controls?.video = video
        let fileManager = FileManager.default
        let path = "\(video.filePath).mp4"
        let fileExists : Bool = fileManager.fileExists(atPath: path)
        if fileExists {
            url = URL(fileURLWithPath: path)
        }
        else if video.downloadState == .complete {
            playerDelegate?.playerDidFailedPlaying(videoPlayer: self, errorMessage: Strings.videoContentNotAvailable)
        }
        let playerItem = AVPlayerItem(url: url)
        player.replaceCurrentItem(with: playerItem)
        loadingIndicatorView.startAnimating()
        addObservers()
        
        var timeInterval: TimeInterval  = 0.0
        if let time = time {
            timeInterval = time
        }
        else {
            timeInterval = TimeInterval(environment.interface?.lastPlayedInterval(forVideo: video) ?? 0)
        }
        
        play(at: timeInterval)
        controls?.isTapButtonHidden = true
        NotificationCenter.default.oex_addObserver(observer: self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime.rawValue, object: player.currentItem as Any) {(notification, observer, _) in
            observer.playerDidFinishPlaying(note: notification)
        }
        perform(#selector(movieTimedOut), with: nil, afterDelay: playerTimeOutInterval)
    }
    
    private func play(at timeInterval: TimeInterval) {
        player.play()
        lastElapsedTime = timeInterval
        var resumeObserver: AnyObject?
        resumeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 3), queue: DispatchQueue.main) { [weak self]
            (elapsedTime: CMTime) -> Void in
            if self?.player.currentItem?.status == .readyToPlay {
                self?.playerState = .playing
                self?.resume(at: timeInterval)
                if let observer = resumeObserver {
                    self?.player.removeTimeObserver(observer)
                }
            }
            } as AnyObject
    }
    
    @objc private func movieTimedOut() {
        stop()
        playerDelegate?.playerDidTimeout(videoPlayer: self)
    }
    
    fileprivate func resume() {
        resume(at: lastElapsedTime)
    }
    
    func resume(at time: TimeInterval) {
        if player.currentItem?.status == .readyToPlay {
            player.currentItem?.seek(to: CMTimeMakeWithSeconds(time, preferredTimescale: preferredTimescale), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero) { [weak self]
                (completed: Bool) -> Void in
                self?.player.play()
                self?.playerState = .playing
                let speed = OEXInterface.getCCSelectedPlaybackSpeed()
                self?.rate = OEXInterface.getOEXVideoSpeed(speed)
            }
        }
    }
    
    fileprivate func pause() {
        player.pause()
        playerState = .paused
        savePlayedTime()
    }
    
    func savePlayedTime(time: TimeInterval? = nil) {
        if ChromeCastManager.shared.isMiniPlayerAdded {
            return
        }
        
        if let time = time {
            lastElapsedTime = time
        }
        else {
            lastElapsedTime = currentTime
        }
        
        if let video = video {
            environment.interface?.markLastPlayedInterval(Float(currentTime), forVideo: video)
            let state = doublesWithinEpsilon(left: duration.seconds, right: currentTime) ? OEXPlayedState.watched : OEXPlayedState.partiallyWatched
            environment.interface?.markVideoState(state, forVideo: video)
        }
    }
    
    fileprivate func stop() {
        savePlayedTime()
        player.actionAtItemEnd = .pause
        player.replaceCurrentItem(with: nil)
        playerState = .stoped
    }
    
    func subTitle(at elapseTime: Float64) -> String {
        return transcriptManager?.transcript(at: elapseTime) ?? ""
    }
    
    fileprivate func addGestures() {
        
        if let _ = playerView.gestureRecognizers?.contains(leftSwipeGestureRecognizer), let _ = playerView.gestureRecognizers?.contains(rightSwipeGestureRecognizer) {
            removeGestures()
        }
        
        playerView.addGestureRecognizer(leftSwipeGestureRecognizer)
        playerView.addGestureRecognizer(rightSwipeGestureRecognizer)
        playerView.addGestureRecognizer(pinchGestureRecognizer)
        if let videoId = video?.summary?.videoID, let courseId = video?.course_id, let unitUrl = video?.summary?.unitURL {
            environment.analytics.trackVideoOrientation(videoId, courseID: courseId, currentTime: CGFloat(currentTime), mode: true, unitURL: unitUrl, playMedium: nil)
        }
    }
    
    private func removeGestures() {
        playerView.removeGestureRecognizer(leftSwipeGestureRecognizer)
        playerView.removeGestureRecognizer(rightSwipeGestureRecognizer)
        playerView.removeGestureRecognizer(pinchGestureRecognizer)
        
        if let videoId = video?.summary?.videoID, let courseId = video?.course_id, let unitUrl = video?.summary?.unitURL {
            environment.analytics.trackVideoOrientation(videoId, courseID: courseId, currentTime: CGFloat(currentTime), mode: false, unitURL: unitUrl, playMedium: nil)
        }
    }
    
    private func removeObservers() {
        if isObserverAdded {
            if let observer = timeObserver {
                player.removeTimeObserver(observer)
                timeObserver = nil
            }
            player.removeObserver(self, forKeyPath: currentItemPlaybackLikelyToKeepUpKey)
            player.removeObserver(self, forKeyPath: currentItemStatusKey)
            NotificationCenter.default.removeObserver(self)
            isObserverAdded = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isVisible = false
        pause()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if !ChromeCastManager.shared.viewExpanded {
            resetPlayer()
        }
    }
    
    func resetPlayer() {
        movieBackgroundView.removeFromSuperview()
        stop()
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(movieTimedOut), object: nil)
        controls?.reset()
    }
    
    func resetPlayerView() {
        if !(view.subviews.contains(playerView)) {
            playerDelegate?.playerWillMoveFromWindow(videoPlayer: self)
            view.addSubview(playerView)
            removeGestures()
            controls?.showHideNextPrevious(isHidden: true)
            updatePlayerConstrainsts(target: safeEdges)
        }
    }
    
    func playerDidFinishPlaying(note: NSNotification) {
        playerDelegate?.playerDidFinishPlaying(videoPlayer: self)
        pause()
        controls?.setPlayPauseButtonState(isSelected: true)
    }
    
    // MARK:- TransctiptManagerDelegate method
    func transcriptsLoaded(manager: TranscriptManager, transcripts: [TranscriptObject]) {
        playerDelegate?.playerDidLoadTranscripts(videoPlayer: self, transcripts: transcripts)
    }
    
    // MARK:- Player control delegate method
    func playPausePressed(playerControls: VideoPlayerControls, isPlaying: Bool) {
        if playerState == .playing {
            pause()
            environment.interface?.sendAnalyticsEvents(.pause, withCurrentTime: currentTime, forVideo: video, playMedium: nil)
        }
        else {

            guard let video = video else { return }

            let playedInterval = environment.interface?.lastPlayedInterval(forVideo: video) ?? 0.0
            let duration = Float(video.summary?.duration ?? 0)

            // Ignore the last second of video because sometimes saved played time is 1 second less duration for a watched video
            if duration > 0 && playedInterval + 1 >= duration {
                // Replay the video
                resume(at: .zero)
            }
            else {
                resume()
            }
            
            environment.interface?.sendAnalyticsEvents(.play, withCurrentTime: currentTime, forVideo: video, playMedium: nil)
        }
    }
    
    func seekBackwardPressed(playerControls: VideoPlayerControls) {
        let oldTime = currentTime
        let videoDuration = CMTimeGetSeconds(duration)
        let elapsedTime: Float64 = videoDuration * Float64(playerControls.durationSliderValue)
        let backTime = elapsedTime > videoSkipBackwardsDuration ? elapsedTime - videoSkipBackwardsDuration : 0.0
        playerControls.updateTimeLabel(elapsedTime: backTime, duration: videoDuration)
        seek(to: backTime)
        
        if let videoId = video?.summary?.videoID, let courseId = video?.course_id, let unitUrl = video?.summary?.unitURL {
            environment.analytics.trackVideoSeek(videoId, requestedDuration:-videoSkipBackwardsDuration, oldTime:oldTime, newTime: currentTime, courseID: courseId, unitURL: unitUrl, skipType: "skip")
        }
    }
    
    func seekForwardPressed(playerControls: VideoPlayerControls) {
        let oldTime = currentTime
        let videoDuration = CMTimeGetSeconds(duration)
        let elapsedTime: Float64 = videoDuration * Float64(playerControls.durationSliderValue)
        let forwardTime = elapsedTime < videoDuration ? elapsedTime + videoSkipForwardsDuration : videoDuration
        playerControls.updateTimeLabel(elapsedTime: forwardTime, duration: videoDuration)
        seek(to: forwardTime)
        
        if let videoId = video?.summary?.videoID, let courseId = video?.course_id, let unitUrl = video?.summary?.unitURL {
            environment.analytics.trackVideoSeek(videoId, requestedDuration:videoSkipForwardsDuration, oldTime:oldTime, newTime: currentTime, courseID: courseId, unitURL: unitUrl, skipType: "skip")
        }
    }
    
    func fullscreenPressed(playerControls: VideoPlayerControls) {
        DispatchQueue.main.async {[weak self] in
            if let weakSelf = self {
                weakSelf.setFullscreen(fullscreen: !weakSelf.isFullScreen, animated: true, with: UIInterfaceOrientation.landscapeLeft, forceRotate:!weakSelf.isVerticallyCompact())
            }
        }
    }
    
    func sliderValueChanged(playerControls: VideoPlayerControls) {
        let videoDuration = CMTimeGetSeconds(duration)
        let elapsedTime: Float64 = videoDuration * Float64(playerControls.durationSliderValue)
        playerControls.updateTimeLabel(elapsedTime: elapsedTime, duration: videoDuration)
    }
    
    func sliderTouchBegan(playerControls: VideoPlayerControls) {
        playerTimeBeforeSeek = currentTime
        player.pause()
        NSObject.cancelPreviousPerformRequests(withTarget: playerControls)
    }
    
    func sliderTouchEnded(playerControls: VideoPlayerControls) {
        let videoDuration = CMTimeGetSeconds(duration)
        let elapsedTime: Float64 = videoDuration * Float64(playerControls.durationSliderValue)
        playerControls.updateTimeLabel(elapsedTime: elapsedTime, duration: videoDuration)
        seek(to: elapsedTime)
        if let videoId = video?.summary?.videoID, let courseId = video?.course_id, let unitUrl = video?.summary?.unitURL {
            environment.analytics.trackVideoSeek(videoId, requestedDuration:currentTime - playerTimeBeforeSeek, oldTime:playerTimeBeforeSeek, newTime: currentTime, courseID: courseId, unitURL: unitUrl, skipType: "slide")
        }
    }
    
    func seek(to time: Double) {
        if player.currentItem?.status != .readyToPlay { return }
        
        player.currentItem?.seek(to: CMTimeMakeWithSeconds(time, preferredTimescale: preferredTimescale), toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero) { [weak self]
            (completed: Bool) -> Void in
            if self?.playerState == .playing {
                self?.controls?.autoHide()
                self?.player.play()
            }
            else {
                self?.savePlayedTime()
            }
        }
    }
    
    fileprivate func setVideoSpeed(speed: OEXVideoSpeed) {
        pause()
        OEXInterface.setCCSelectedPlaybackSpeed(speed)
        resume()
    }
    
    func hideAndShowControls(isHidden: Bool) {
        controls?.hideAndShowControls(isHidden: isHidden)
    }
    
    // MARK:- VideoPlayer Controls Delegate Methods
    func setPlayBackSpeed(playerControls: VideoPlayerControls, speed: OEXVideoSpeed) {
        let oldSpeed = rate
        setVideoSpeed(speed: speed)
        
        if let videoId = video?.summary?.videoID, let courseId = video?.course_id, let unitUrl = video?.summary?.unitURL {
            environment.analytics.trackVideoSpeed(videoId, currentTime: currentTime, courseID: courseId, unitURL: unitUrl, oldSpeed: String(format: "%.1f", oldSpeed), newSpeed: String(format: "%.1f", OEXInterface.getOEXVideoSpeed(speed)))
        }
    }
    
    func captionUpdate(playerControls: VideoPlayerControls, language: String) {
        OEXInterface.setCCSelectedLanguage(language)
        if language.isEmpty {
            playerControls.deAvtivateSubTitles()
        }
        else {
            transcriptManager?.loadTranscripts()
            playerControls.activateSubTitles()
            if let videoId = video?.summary?.videoID, let courseId = video?.course_id, let unitUrl = video?.summary?.unitURL {
                environment.analytics.trackTranscriptLanguage(videoId, currentTime: currentTime, language: language, courseID: courseId, unitURL: unitUrl)
            }
        }
    }
    
    func setVideo(video: OEXHelperVideoDownload){
        self.video = video
    }
    
    deinit {
        removeObservers()
    }
    
    func setFullscreen(fullscreen: Bool, animated: Bool, with deviceOrientation: UIInterfaceOrientation, forceRotate rotate: Bool) {
        if !isVisible { return }
        isFullScreen = fullscreen
        if fullscreen {
            
            fullScreenContainerView = UIApplication.shared.keyWindow?.rootViewController?.view ?? UIApplication.shared.windows[0].rootViewController?.view
            
            if movieBackgroundView.frame == .zero {
                movieBackgroundView.frame = movieBackgroundFrame
            }
            
            if let subviews = fullScreenContainerView?.subviews, !subviews.contains(movieBackgroundView){
                fullScreenContainerView?.addSubview(movieBackgroundView)
            }
            
            UIView.animate(withDuration: animated ? 0.1 : 0.0, delay: 0.0, options: .curveLinear, animations: {[weak self]() -> Void in
                self?.movieBackgroundView.alpha = 1.0
                }, completion: {[weak self](_ finished: Bool) -> Void in
                    self?.view.alpha = 0.0
                    if let owner = self {
                        if !(owner.movieBackgroundView.subviews.contains(owner.playerView)) {
                            owner.movieBackgroundView.addSubview(owner.playerView)
                            owner.movieBackgroundView.layer.insertSublayer(owner.playerView.playerLayer, at: 0)
                            owner.addGestures()
                            owner.controls?.showHideNextPrevious(isHidden: false)
                            owner.updatePlayerConstrainsts(target: owner.movieBackgroundView)
                        }
                    }
                    self?.rotateMoviePlayer(for: deviceOrientation, animated: animated, forceRotate: rotate, completion: {[weak self]() -> Void in
                        UIView.animate(withDuration: animated ? 0.1 : 0.0, delay: 0.0, options: .curveLinear, animations: {[weak self]() -> Void in
                            self?.view.alpha = 1.0
                            }, completion: nil)
                    })
            })
        }
        else {
            UIView.animate(withDuration: animated ? 0.1 : 0.0, delay: 0.0, options: .curveLinear, animations: {[weak self]() -> Void in
                self?.view.alpha = 0.0
                }, completion: {[weak self](_ finished: Bool) -> Void in
                    self?.view.alpha = 1.0
                    UIView.animate(withDuration: animated ? 0.1 : 0.0, delay: 0.0, options: .curveLinear, animations: {[weak self]() -> Void in
                        self?.movieBackgroundView.alpha = 0.0
                        }, completion: {[weak self](_ finished: Bool) -> Void in
                            self?.movieBackgroundView.removeFromSuperview()
                            self?.resetPlayerView()
                    })
            })
        }
    }
}

extension VideoPlayer {
    
    var movieBackgroundFrame: CGRect {
        return UIScreen.main.bounds
    }
    
    func rotateMoviePlayer(for orientation: UIInterfaceOrientation, animated: Bool, forceRotate rotate: Bool, completion: (() -> Void)? = nil) {
        var angle: Double = 0
        var movieFrame: CGRect = CGRect(x: movieBackgroundFrame.maxX, y: movieBackgroundFrame.maxY, width: movieBackgroundFrame.width, height: movieBackgroundFrame.height)
        
        // Used to rotate the view on Fulscreen button click
        // Rotate it forcefully as the orientation is on the UIDeviceOrientation
        if rotate && orientation == .landscapeLeft {
            angle = Double.pi/2
            // MOB-1053
            movieFrame = CGRect(x: movieBackgroundFrame.maxX, y: movieBackgroundFrame.maxY, width: movieBackgroundFrame.height, height: movieBackgroundFrame.width)
        }
        else if rotate && orientation == .landscapeRight {
            angle = -Double.pi/2
            // MOB-1053
            movieFrame = CGRect(x: movieBackgroundFrame.maxX, y: movieBackgroundFrame.maxY, width: movieBackgroundFrame.height, height: movieBackgroundFrame.width)
        }
        
        if animated {
            UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseInOut, animations: { [weak self] in
                if let weakSelf = self {
                    weakSelf.movieBackgroundView.transform = CGAffineTransform(rotationAngle: CGFloat(angle))
                    weakSelf.movieBackgroundView.frame = weakSelf.movieBackgroundFrame
                    weakSelf.view.frame = movieFrame
                }
                }, completion: nil)
        }
        else {
            movieBackgroundView.transform = CGAffineTransform(rotationAngle: CGFloat(angle))
            movieBackgroundView.frame = movieBackgroundFrame
            view.frame = movieFrame
        }
    }
}

// Specific for test cases
extension VideoPlayer {
    var t_controls: VideoPlayerControls? {
        return controls
    }
    
    var t_video: OEXHelperVideoDownload? {
        return video
    }
    
    var t_playerCurrentState: AVPlayerItem.Status {
        return player.currentItem?.status ?? .unknown
    }
    
    var t_playBackSpeed: OEXVideoSpeed {
        set {
            setVideoSpeed(speed: newValue)
        }
        get {
            return OEXInterface.getCCSelectedPlaybackSpeed()
        }
    }
    
    var t_subtitleActivated: Bool {
        return controls?.t_subtitleActivated ?? false
    }
    
    var t_captionLanguage: String {
        set {
            controls?.setCaption(language: newValue)
        }
        get {
            return OEXInterface.getCCSelectedLanguage() ?? "en"
        }
    }
    
    func t_pause() {
        pause()
    }
    
    func t_stop() {
        stop()
    }
    
    func t_resume() {
        resume()
    }
    
    @objc fileprivate func t_postNotification() {
        //This notification call specifically for test cases in readyToPlay state
        NotificationCenter.default.post(name: Notification.Name.init("TestPlayerStatusDidChangedToReadyState"), object: nil)
    }
}
