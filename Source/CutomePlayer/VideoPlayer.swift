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
         stop
}

protocol VideoPlayerControllerDelegate {
    func playerDidLoadTranscripts(videoPlayer:VideoPlayer, transcripts: [TranscriptObject])
    func playerWillMoveFromWindow(videoPlayer: VideoPlayer)
    func playerDidStopPlaying(videoPlayer: VideoPlayer, duration: Double, currentTime: Double)
    func playerDidTimedOut(videoPlayer: VideoPlayer)
    func playerDidFinishPlaying(videoPlayer: VideoPlayer)
}

private var playbackLikelyToKeepUpContext = 0
class VideoPlayer: UIViewController,VideoPlayerControlsDelegate,TranscriptManagerDelegate {
    
    typealias Environment = OEXInterfaceProvider & OEXAnalyticsProvider
    
    let environment : Environment
    var playerControls: VideoPlayerControls?
    var playerDelegate : VideoPlayerControllerDelegate?
    var isFullScreen : Bool = false
    fileprivate let playerView = PlayerView()
    private var timeObserver : AnyObject?
    let videoPlayer = AVPlayer()
    private let loadingIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .white)
    private var lastElapsedTime: TimeInterval = 0
    private var transcriptManager: TranscriptManager?
    private let videoSkipBackwardsDuration: Double = 30
    private var playerTimeBeforeSeek:TimeInterval = 0
    private var playerState: PlayerState = .stop
    private var isObserverAdded: Bool = false
    private let currentItemStatusKey = "currentItem.status"
    private let loadingIndicatorViewSize = CGSize(width: 50.0, height: 50.0)
    
    var video : OEXHelperVideoDownload? {
        didSet {
            initializeSubtitles()
        }
    }
    
    lazy fileprivate var movieBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black
        view.alpha = 0.5
        return view
    }()
    
    var rate: Float {
        get {
            return videoPlayer.rate
        }
        set {
            videoPlayer.rate = newValue
        }
    }
    
    var duration: CMTime {
        return videoPlayer.currentItem?.duration ?? CMTime()
    }
    
    var currentTime: TimeInterval {
        return videoPlayer.currentItem?.currentTime().seconds ?? 0
    }
    
    var playableDuration: TimeInterval {
        var result: TimeInterval = 0
        if let loadedTimeRanges = videoPlayer.currentItem?.loadedTimeRanges, loadedTimeRanges.count > 0  {
            let timeRange = loadedTimeRanges[0].timeRangeValue
            let startSeconds: Float64 = CMTimeGetSeconds(timeRange.start)
            let durationSeconds: Float64 = CMTimeGetSeconds(timeRange.duration)
            result =  TimeInterval(startSeconds) + TimeInterval(durationSeconds)
        }
        return result
    }
    
    var leftSwipeGestureRecognizer : UISwipeGestureRecognizer = {
        let gesture = UISwipeGestureRecognizer()
        gesture.direction = .left
        return gesture
    }()
    
    var rightSwipeGestureRecognizer : UISwipeGestureRecognizer = {
        let gesture = UISwipeGestureRecognizer()
        gesture.direction = .right
        return gesture
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
    
   private func addObservers() {
        if !isObserverAdded {
            isObserverAdded = true
            videoPlayer.addObserver(self, forKeyPath: "currentItem.playbackLikelyToKeepUp",
                                    options: .new, context: &playbackLikelyToKeepUpContext)
        
            videoPlayer.addObserver(self, forKeyPath: currentItemStatusKey,
                                    options: .new, context: nil)
        
            let timeInterval: CMTime = CMTimeMakeWithSeconds(1.0, 10)
            timeObserver = videoPlayer.addPeriodicTimeObserver(forInterval: timeInterval, queue: DispatchQueue.main) { [weak self]
                (elapsedTime: CMTime) -> Void in
                self?.observeProgress(elapsedTime: elapsedTime)
                } as AnyObject
        }
    }
    
    private func observeProgress(elapsedTime: CMTime) {
        let duration = CMTimeGetSeconds(self.duration)
        if duration.isFinite {
            let elapsedTime = CMTimeGetSeconds(elapsedTime)
            playerControls?.durationSliderValue = Float(elapsedTime / duration)
            playerControls?.updateTimeLabel(elapsedTime: elapsedTime, duration: duration)
        }
    }
    
   private func createPlayer() {
        view.addSubview(playerView)
        playerView.playerLayer.player = videoPlayer
        view.layer.insertSublayer(playerView.playerLayer, at: 0)
        playerControls = VideoPlayerControls(with: self)
        playerControls?.delegate = self
        if let controls = playerControls {
            playerView.addSubview(controls)
        }
        playerView.addSubview(loadingIndicatorView)
        
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: [])
        setConstraints()
    }
    
   private func initializeSubtitles() {
        if let video = video {
            transcriptManager = TranscriptManager(environment: environment, video: video)
            transcriptManager?.delegate = self
            
            if let ccSelectedLanguage = OEXInterface.getCCSelectedLanguage(), let transcriptURL = video.summary?.transcripts?[ccSelectedLanguage] as? String, !ccSelectedLanguage.isEmpty, !transcriptURL.isEmpty {
                playerControls?.activateSubTitles()
            }
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        playerView.frame = view.bounds
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &playbackLikelyToKeepUpContext, let currentItem = videoPlayer.currentItem {
            if currentItem.isPlaybackLikelyToKeepUp {
                loadingIndicatorView.stopAnimating()
            } else {
                loadingIndicatorView.startAnimating()
            }
        }
        else if keyPath == currentItemStatusKey {
            if let newStatusAsNumber = change?[NSKeyValueChangeKey.newKey] as? NSNumber {
                let newStatus: AVPlayerItemStatus
                newStatus = AVPlayerItemStatus(rawValue: newStatusAsNumber.intValue)!
                switch newStatus {
                case .readyToPlay:
                    NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(movieTimedOut), object: nil)
                    playerControls?.isTapButtonHidden = false
                    break
                case .unknown:
                    playerControls?.isTapButtonHidden = true
                    break
                case .failed:
                    playerControls?.isTapButtonHidden = true
                    break
                }
            }
        }
    }
    
    private func setConstraints() {
        if let playerControls = playerControls {
            playerControls.snp_makeConstraints() { make in
                make.edges.equalTo(playerView)
            }
            loadingIndicatorView.snp_makeConstraints() { make in
                make.center.equalTo(playerView.center)
                make.height.equalTo(loadingIndicatorViewSize.height)
                make.width.equalTo(loadingIndicatorViewSize.width)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        addObservers()
        defaultScreenOrientation()
    }
    
    private func defaultScreenOrientation() {
        if isVerticallyCompact() {
            setFullscreen(fullscreen: true, animated: false, with: UIInterfaceOrientation.portrait, forceRotate: false)
        }
    }
    
     func play(video : OEXHelperVideoDownload) {
        playerControls?.video = video
        self.video = video
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
            if let url = url {
                let playerItem = AVPlayerItem(url: url)
                videoPlayer.replaceCurrentItem(with: playerItem)
            }
            
            let timeInterval = TimeInterval(environment.interface?.lastPlayedInterval(forVideo: video) ?? 0)
            play(at: timeInterval)
            playerControls?.isTapButtonHidden = true
            NotificationCenter.default.oex_addObserver(observer: self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime.rawValue, object: videoPlayer.currentItem as Any) {[weak self] (notification, _, _) in
                self?.playerDidFinishPlaying(note: notification)
            }
            perform(#selector(movieTimedOut), with: nil, afterDelay: 60)
        }
    }
    
    func play(at timeInterval: TimeInterval) {
        videoPlayer.play()
        lastElapsedTime = timeInterval
        var resumeObserver: AnyObject?
        resumeObserver = videoPlayer.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 3), queue: DispatchQueue.main) { [weak self]
            (elapsedTime: CMTime) -> Void in
            if self?.videoPlayer.currentItem?.status == .readyToPlay {
                self?.playerState = .playing
                self?.resume(at: timeInterval)
                if let observer = resumeObserver {
                    self?.videoPlayer.removeTimeObserver(observer)
                }
            }
        } as AnyObject
    }
    
   @objc private func movieTimedOut() {
        stop()
        playerDelegate?.playerDidTimedOut(videoPlayer: self)
    }
    
    private func resume() {
        resume(at: lastElapsedTime)
    }
    
    func resume(at time: TimeInterval) {
        videoPlayer.currentItem?.seek(to: CMTimeMakeWithSeconds(time, 100), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero) { [weak self]
            (completed: Bool) -> Void in
            self?.videoPlayer.play()
        }
    }
    
    private func pause() {
        videoPlayer.pause()
        playerState = .paused
        saveCurrentTime()
    }
    
    private func saveCurrentTime() {
        lastElapsedTime = currentTime
        playerDelegate?.playerDidStopPlaying(videoPlayer: self, duration: duration.seconds, currentTime: currentTime)
    }
    
    private func stop() {
        saveCurrentTime()
        videoPlayer.actionAtItemEnd = AVPlayerActionAtItemEnd.pause
        videoPlayer.replaceCurrentItem(with: nil)
        playerState = .stop
    }
    
    func subTitle(at elapseTime: Float64) -> String {
        return transcriptManager?.transcript(at: elapseTime) ?? ""
    }
    
    func addGestures() {
        
        if let _ = playerView.gestureRecognizers?.contains(leftSwipeGestureRecognizer), let _ = playerView.gestureRecognizers?.contains(rightSwipeGestureRecognizer) {
            removeGestures()
        }
        
        leftSwipeGestureRecognizer.addAction {[weak self] _ in
            self?.playerControls?.nextButtonClicked()
        }
        rightSwipeGestureRecognizer.addAction {[weak self] _ in
            self?.playerControls?.previousButtonClicked()
        }
        playerView.addGestureRecognizer(leftSwipeGestureRecognizer)
        playerView.addGestureRecognizer(rightSwipeGestureRecognizer)
        
        if let videoId = video?.summary?.videoID, let courseId = video?.course_id, let unitUrl = video?.summary?.unitURL {
            environment.analytics.trackVideoOrientation(videoId, courseID: courseId, currentTime: CGFloat(currentTime), mode: true, unitURL: unitUrl)
        }
    }
    
    func removeGestures() {
        playerView.removeGestureRecognizer(leftSwipeGestureRecognizer)
        playerView.removeGestureRecognizer(rightSwipeGestureRecognizer)
        
        if let videoId = video?.summary?.videoID, let courseId = video?.course_id, let unitUrl = video?.summary?.unitURL {
            environment.analytics.trackVideoOrientation(videoId, courseID: courseId, currentTime: CGFloat(currentTime), mode: false, unitURL: unitUrl)
        }
    }
    
   private func removeObservers() {
        if isObserverAdded {
            if let observer = timeObserver {
                videoPlayer.removeTimeObserver(observer)
                timeObserver = nil
            }
            videoPlayer.removeObserver(self, forKeyPath: "currentItem.playbackLikelyToKeepUp")
            videoPlayer.removeObserver(self, forKeyPath: currentItemStatusKey)
            NotificationCenter.default.removeObserver(self)
            isObserverAdded = false
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stop()
        removeObservers()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func resetPlayerView() {
        movieBackgroundView.removeFromSuperview()
        if !(view.subviews.contains(playerView)) {
            playerDelegate?.playerWillMoveFromWindow(videoPlayer: self)
            view.addSubview(playerView)
            view.setNeedsLayout()
            view.layoutIfNeeded()
            removeGestures()
            playerControls?.showHideNextPrevious(isHidden: true)
        }
    }
    
    
    
    func playerDidFinishPlaying(note: NSNotification) {
        playerDelegate?.playerDidFinishPlaying(videoPlayer: self)
    }
    
    // MARK: TransctiptManagerDelegate method
    func transcriptsLoaded(transcripts: [TranscriptObject]) {
        playerDelegate?.playerDidLoadTranscripts(videoPlayer: self, transcripts: transcripts)
    }
    
    // MARK: Player control delegate method
    func playPausePressed(playerControls: VideoPlayerControls, isPlaying: Bool) {
        if videoPlayer.isPlaying {
            pause()
            environment.interface?.sendAnalyticsEvents(.pause, withCurrentTime: currentTime, forVideo: video)
        }
        else {
            resume()
            environment.interface?.sendAnalyticsEvents(.play, withCurrentTime: currentTime, forVideo: video)
        }
    }
    
    func seekBackwardPressed(playerControls: VideoPlayerControls) {
        let oldTime = currentTime
        let videoDuration = CMTimeGetSeconds(duration)
        let elapsedTime: Float64 = videoDuration * Float64(playerControls.durationSliderValue)
        let backTime = elapsedTime > videoSkipBackwardsDuration ? elapsedTime - videoSkipBackwardsDuration : 0.0
        playerControls.updateTimeLabel(elapsedTime: backTime, duration: videoDuration)
        videoPlayer.seek(to: CMTimeMakeWithSeconds(backTime, 100)) { [weak self]
            (completed: Bool) -> Void in
            self?.videoPlayer.play()
        }
        
        if let videoId = video?.summary?.videoID, let courseId = video?.course_id, let unitUrl = video?.summary?.unitURL {
            environment.analytics.trackVideoSeekRewind(videoId, requestedDuration:-videoSkipBackwardsDuration, oldTime:oldTime, newTime: currentTime, courseID: courseId, unitURL: unitUrl, skipType: "skip")
        }
    }
    
    func fullscreenPressed(playerControls: VideoPlayerControls) {
        if (UIInterfaceOrientationIsPortrait(UIApplication.shared.statusBarOrientation)) {
            setFullscreen(fullscreen: !isFullScreen, animated: true, with: UIInterfaceOrientation.landscapeLeft, forceRotate:true)
        }
        else {
            setFullscreen(fullscreen: !isFullScreen, animated: true, with: UIInterfaceOrientation.landscapeLeft, forceRotate:false)
        }
    }
    
    func sliderValueChanged(playerControls: VideoPlayerControls) {
        let videoDuration = CMTimeGetSeconds(duration)
        let elapsedTime: Float64 = videoDuration * Float64(playerControls.durationSliderValue)
        playerControls.updateTimeLabel(elapsedTime: elapsedTime, duration: videoDuration)
    }
    
    func sliderTouchBegan(playerControls: VideoPlayerControls) {
        playerTimeBeforeSeek = currentTime
        videoPlayer.pause()
        NSObject.cancelPreviousPerformRequests(withTarget:playerControls)
    }
    
    func sliderTouchEnded(playerControls: VideoPlayerControls) {
        let videoDuration = CMTimeGetSeconds(duration)
        let elapsedTime: Float64 = videoDuration * Float64(playerControls.durationSliderValue)
        playerControls.updateTimeLabel(elapsedTime: elapsedTime, duration: videoDuration)
        
        videoPlayer.seek(to: CMTimeMakeWithSeconds(elapsedTime, 100)) { [weak self]
            (completed: Bool) -> Void in
            if self?.playerState == .playing {
                playerControls.autoHide()
                self?.videoPlayer.play()
            }
            else {
                self?.saveCurrentTime()
            }
        }
        
        if let videoId = video?.summary?.videoID, let courseId = video?.course_id, let unitUrl = video?.summary?.unitURL {
            environment.analytics.trackVideoSeekRewind(videoId, requestedDuration:currentTime - playerTimeBeforeSeek, oldTime:playerTimeBeforeSeek, newTime: currentTime, courseID: courseId, unitURL: unitUrl, skipType: "slide")
        }
    }
    
    func setPlayBackSpeed(playerControls: VideoPlayerControls, speed:OEXVideoSpeed) {
        let oldSpeed = rate
        let playbackRate = OEXInterface.getOEXVideoSpeed(speed)
        OEXInterface.setCCSelectedPlaybackSpeed(speed)
        rate = playbackRate
        
        if let videoId = video?.summary?.videoID, let courseId = video?.course_id, let unitUrl = video?.summary?.unitURL {
            environment.analytics.trackVideoSpeed(videoId, currentTime: currentTime, courseID: courseId, unitURL: unitUrl, oldSpeed: String(format: "%.1f", oldSpeed), newSpeed: String.init(format: "%.1f", playbackRate))
        }
    }
}

extension VideoPlayer {
    func setFullscreen(fullscreen: Bool, animated: Bool, with deviceOrientation: UIInterfaceOrientation, forceRotate rotate: Bool) {
        isFullScreen = fullscreen
        if fullscreen {
            var keyWindow: UIWindow? = UIApplication.shared.keyWindow
            if keyWindow == nil {
                keyWindow = UIApplication.shared.windows[0]
            }
            let container: UIView? = keyWindow?.rootViewController?.view
            if let containerBounds = container?.bounds {
                movieBackgroundView.frame = containerBounds
            }
            container?.addSubview(movieBackgroundView)
            if !(movieBackgroundView.subviews.contains(playerView)) {
                movieBackgroundView.addSubview(playerView)
                movieBackgroundView.layer.insertSublayer(playerView.playerLayer, at: 0)
                addGestures()
                playerControls?.showHideNextPrevious(isHidden: false)
            }
            UIView.animate(withDuration: animated ? 0.1 : 0.0, delay: 0.0, options: .curveLinear, animations: {[weak self]() -> Void in
                self?.movieBackgroundView.alpha = 1.0
                }, completion: {[weak self](_ finished: Bool) -> Void in
                    self?.view.alpha = 0.0
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
                            self?.resetPlayerView()
                    })
            })
        }
    }
    
    func rotateMoviePlayer(for orientation: UIInterfaceOrientation, animated: Bool, forceRotate rotate: Bool, completion: (() -> Void)? = nil) {
        var angle: Double = 0
        
        let windowSize = UIScreen.main.bounds.size
        
        var backgroundFrame: CGRect = CGRect(x: 0, y: 0, width: windowSize.width, height: windowSize.height)
        var movieFrame: CGRect = CGRect(x: 0, y: 0, width: backgroundFrame.size.width, height: backgroundFrame.size.height)
        
        // Used to rotate the view on Fulscreen button click
        // Rotate it forcefully as the orientation is on the UIDeviceOrientation
        if rotate && orientation == .landscapeLeft {
            angle = Double.pi/2
            // MOB-1053
            backgroundFrame = CGRect(x: 0, y: 0, width: windowSize.width, height: windowSize.height)
            movieFrame = CGRect(x: 0, y: 0, width: backgroundFrame.size.height, height: backgroundFrame.size.width);
        }
        else if rotate && orientation == .landscapeRight {
            angle = -Double.pi/2
            // MOB-1053
            backgroundFrame = CGRect(x: 0, y: 0, width: windowSize.width, height: windowSize.height)
            movieFrame = CGRect(x: 0, y: 0, width: backgroundFrame.size.height, height: backgroundFrame.size.width);
        }
        
        if animated {
            UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseInOut, animations: {[weak self]() -> Void in
                self?.movieBackgroundView.transform = CGAffineTransform(rotationAngle: CGFloat(angle))
                self?.movieBackgroundView.frame = backgroundFrame
                self?.view.frame = movieFrame
                }, completion: nil)
        }
        else {
            movieBackgroundView.transform = CGAffineTransform(rotationAngle: CGFloat(angle))
            movieBackgroundView.frame = backgroundFrame
            view.frame = movieFrame
        }
    }
}

extension AVPlayer {
    var isPlaying: Bool {
        return rate != 0 && error == nil
    }
}
