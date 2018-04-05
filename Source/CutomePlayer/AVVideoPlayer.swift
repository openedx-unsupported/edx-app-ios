//
//  AVVideoPlayer.swift
//  edX
//
//  Created by Salman on 05/03/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit
import AVKit

private enum PlayerState {
    case Playing
    case Paused
    case Stop
}

protocol VideoPlayerControllerDelegate {
    func transcriptLoaded(transcripts: [TranscriptObject])
    func moviePlayerWillMoveFromWindow()
    func playerDidStopPlaying(duration: Double, currentTime: Double)
    func movieTimedOut()
    func didFinishVideoPlaying()
}

private var playbackLikelyToKeepUpContext = 0
@objc class AVVideoPlayer: UIViewController,VideoPlayerControlsDelegate,TranscriptManagerDelegate {
    
    var contentURL : URL?
    var playerControls: VideoPlayerControls?
    var playerDelegate : VideoPlayerControllerDelegate?
    var movieFullscreen : Bool = false
    let playerView = PlayerView()
    var height: Double = 0
    var width: Double = 0
    var defaultFrame : CGRect = CGRect.zero
    private var timeObserver : AnyObject?
    let videoPlayer = AVPlayer()
    private let loadingIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .white)
    private var lastElapsedTime: TimeInterval = 0
    private var transcriptManager: TranscriptManager?
    private let videoSkipBackwardsDuration: Double = 30
    private var playerStartTime: TimeInterval = 0
    private var playerStopTime: TimeInterval = 0
    private var playerState: PlayerState = .Stop
    private var isObserverAdded: Bool = false
    var video : OEXHelperVideoDownload? {
        didSet {
            initializeSubtitles()
        }
    }
    
    lazy var movieBackgroundView: UIView = {
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
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createPlayer()
        addObservers()
        view.backgroundColor = .black
        loadingIndicatorView.hidesWhenStopped = true
    }
    
   private func addObservers() {
    
        videoPlayer.addObserver(self, forKeyPath: "currentItem.playbackLikelyToKeepUp",
                                options: .new, context: &playbackLikelyToKeepUpContext)
    
        videoPlayer.addObserver(self, forKeyPath: "currentItem.status",
                                options: .new, context: nil)
    
        let timeInterval: CMTime = CMTimeMakeWithSeconds(1.0, 10)
        timeObserver = videoPlayer.addPeriodicTimeObserver(forInterval: timeInterval, queue: DispatchQueue.main) { [weak self]
            (elapsedTime: CMTime) -> Void in
            self?.observeTime(elapsedTime: elapsedTime)
            } as AnyObject
        isObserverAdded = true
    }
    
    private func observeTime(elapsedTime: CMTime) {
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
        let controls = VideoPlayerControls(with: self)
        controls.delegate = self
        playerControls = controls
        playerView.addSubview(controls)
        playerView.addSubview(loadingIndicatorView)
        
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: [])
        setControlsConstraints()
    }
    
   private func initializeSubtitles() {
        if let video = video {
            transcriptManager = TranscriptManager(with: video)
            transcriptManager?.delegate = self
            
            if let ccSelectedLanguage = OEXInterface.getCCSelectedLanguage(), let url = video.summary?.transcripts?[ccSelectedLanguage] as? String, ccSelectedLanguage != "", url != "" {
                playerControls?.activateSubTitles()
            }
        }
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        playerView.frame = view.bounds
        defaultFrame = CGRect(x: 0, y: 0, width: width, height: height)
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &playbackLikelyToKeepUpContext, let currentItem = videoPlayer.currentItem {
            if currentItem.isPlaybackLikelyToKeepUp {
                loadingIndicatorView.stopAnimating()
            } else {
                loadingIndicatorView.startAnimating()
            }
        }
        else if keyPath == "currentItem.status" {
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
    
    private func setControlsConstraints() {
        if let playerControls = playerControls {
            playerControls.snp_makeConstraints() { make in
                make.edges.equalTo(playerView)
            }
            loadingIndicatorView.snp_makeConstraints() { make in
                make.center.equalTo(playerView.center)
                make.height.equalTo(50)
                make.width.equalTo(50)
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkForOrientation()
    }
    
   private func checkForOrientation() {
        if currentOrientation().isLandscape {
            setFullscreen(fullscreen: true, animated: false, with: UIInterfaceOrientation.portrait, forceRotate: false)
        }
    }
    
    func play() {
        if let url = contentURL {
            let playerItem = AVPlayerItem(url: url)
            videoPlayer.replaceCurrentItem(with: playerItem)
        }
        videoPlayer.play()
        playerControls?.isTapButtonHidden = true
        NotificationCenter.default.oex_addObserver(observer: self, name: NSNotification.Name.AVPlayerItemDidPlayToEndTime.rawValue, object: videoPlayer.currentItem as Any) { (notification, _, _) in
            self.playerDidFinishPlaying(note: notification)
        }
        perform(#selector(movieTimedOut), with: nil, afterDelay: 60)
    }
    
    func play(at timeInterval: TimeInterval) {
        play()
        lastElapsedTime = timeInterval
        var resumeObserver: AnyObject?
        resumeObserver = videoPlayer.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 3), queue: DispatchQueue.main) { [weak self]
            (elapsedTime: CMTime) -> Void in
            if self?.videoPlayer.currentItem?.status == .readyToPlay {
                self?.resume(at: timeInterval)
                if let observer = resumeObserver {
                    self?.videoPlayer.removeTimeObserver(observer)
                }
            }
            
            } as AnyObject
    }
    
   @objc private func movieTimedOut() {
        stop()
        playerDelegate?.movieTimedOut()
    }
    
    func resume() {
        resume(at: lastElapsedTime)
    }
    
    func resume(at time: TimeInterval) {
        videoPlayer.currentItem?.seek(to: CMTimeMakeWithSeconds(time, 100), toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero) { [weak self]
            (completed: Bool) -> Void in
            self?.videoPlayer.play()
        }
    }
    
    func pause() {
        videoPlayer.pause()
        saveCurrentTime()
    }
    
    func saveCurrentTime() {
        lastElapsedTime = currentTime
        playerDelegate?.playerDidStopPlaying(duration: duration.seconds, currentTime: currentTime)
    }
    
    func stop() {
        playerDelegate?.playerDidStopPlaying(duration: duration.seconds, currentTime: currentTime)
        videoPlayer.actionAtItemEnd = AVPlayerActionAtItemEnd.pause
        videoPlayer.replaceCurrentItem(with: nil)
    }
    
    func subTitle(at elapseTime: Float64) -> String {
        return transcriptManager?.transcript(at: elapseTime) ?? ""
    }
    
    func addGesture() {
        playerView.leftSwipeGestureRecognizer.addAction {[weak self] _ in
            self?.playerControls?.nextButtonClicked()
        }
        playerView.rightSwipeGestureRecognizer.addAction {[weak self] _ in
            self?.playerControls?.previousButtonClicked()
        }
        
        playerView.addGesture(gesture: playerView.leftSwipeGestureRecognizer)
        playerView.addGesture(gesture: playerView.rightSwipeGestureRecognizer)
        
        if let videoId = video?.summary?.videoID, let courseId = video?.course_id, let unitUrl = video?.summary?.unitURL {
            OEXAnalytics.shared().trackVideoOrientation(videoId, courseID: courseId, currentTime: CGFloat(self.currentTime), mode: true, unitURL: unitUrl)
        }
    }
    
    func removeGesture() {
        playerView.removeGesture(gesture: playerView.leftSwipeGestureRecognizer)
        playerView.removeGesture(gesture: playerView.rightSwipeGestureRecognizer)
        
        if let videoId = video?.summary?.videoID, let courseId = video?.course_id, let unitUrl = video?.summary?.unitURL {
            OEXAnalytics.shared().trackVideoOrientation(videoId, courseID: courseId, currentTime: CGFloat(self.currentTime), mode: false, unitURL: unitUrl)
        }
    }
    
   private func removeObservers() {
        if isObserverAdded {
            if let observer = timeObserver {
                videoPlayer.removeTimeObserver(observer)
                timeObserver = nil
            }
            videoPlayer.removeObserver(self, forKeyPath: "currentItem.playbackLikelyToKeepUp")
            videoPlayer.removeObserver(self, forKeyPath: "currentItem.status")
            NotificationCenter.default.removeObserver(self)
            isObserverAdded = false
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        stop()
        playerState = .Stop
        removeObservers()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func resetView() {
        movieBackgroundView.removeFromSuperview()
        if !(view.subviews.contains(playerView)) {
            view.addSubview(playerView)
            view.frame = defaultFrame
            removeGesture()
            playerControls?.showHideNextPrevious(isHidden: true)
        }
    }
    
    func setFullscreen(fullscreen: Bool, animated: Bool, with deviceOrientation: UIInterfaceOrientation, forceRotate rotate: Bool) {
        movieFullscreen = fullscreen
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
                addGesture()
                playerControls?.showHideNextPrevious(isHidden: false)
            }
            UIView.animate(withDuration: animated ? 0.1 : 0.0, delay: 0.0, options: .curveLinear, animations: {() -> Void in
                self.movieBackgroundView.alpha = 1.0
            }, completion: {(_ finished: Bool) -> Void in
                self.view.alpha = 0.0
                self.rotateMoviePlayer(for: deviceOrientation, animated: animated, forceRotate: rotate, completion: {() -> Void in
                    UIView.animate(withDuration: animated ? 0.1 : 0.0, delay: 0.0, options: .curveLinear, animations: {() -> Void in
                        self.view.alpha = 1.0
                    }, completion: {(_ finished: Bool) -> Void in
                    })
                })
            })
        }
        else {
            
            UIView.animate(withDuration: animated ? 0.1 : 0.0, delay: 0.0, options: .curveLinear, animations: {() -> Void in
                self.view.alpha = 0.0
            }, completion: {(_ finished: Bool) -> Void in
                self.view.alpha = 1.0
                UIView.animate(withDuration: animated ? 0.1 : 0.0, delay: 0.0, options: .curveLinear, animations: {() -> Void in
                    self.movieBackgroundView.alpha = 0.0
                }, completion: {(_ finished: Bool) -> Void in
                    self.resetView()
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
            UIView.animate(withDuration: 0.1, delay: 0.0, options: .curveEaseInOut, animations: {() -> Void in
                self.movieBackgroundView.transform = CGAffineTransform(rotationAngle: CGFloat(angle))
                self.movieBackgroundView.frame = backgroundFrame
                self.view.frame = movieFrame
            }, completion: {(_ finished: Bool) -> Void in
            })
        }
        else {
            movieBackgroundView.transform = CGAffineTransform(rotationAngle: CGFloat(angle))
            movieBackgroundView.frame = backgroundFrame
            self.view.frame = movieFrame
        }
    }
    
    func playerDidFinishPlaying(note: NSNotification) {
        playerDelegate?.didFinishVideoPlaying()
    }
    
    // MARK: TransctiptManagerDelegate method
    func transcriptsLoaded(transcripts: [TranscriptObject]) {
        playerDelegate?.transcriptLoaded(transcripts: transcripts)
    }
    
    // MARK: Player control delegate method
    func playPausePressed(isPlaying: Bool) {
        if videoPlayer.isPlaying {
            pause()
            playerState = .Paused
            OEXInterface.shared().sendAnalyticsEvents(.pause, withCurrentTime: self.currentTime, forVideo: video)
        }
        else {
            resume()
            playerState = .Playing
            OEXInterface.shared().sendAnalyticsEvents(.play, withCurrentTime: self.currentTime, forVideo: video)
        }
    }
    
    func seekBackwardPressed() {
        let oldTime = self.currentTime
        let videoDuration = CMTimeGetSeconds(self.duration)
        let elapsedTime: Float64 = videoDuration * Float64(playerControls?.durationSliderValue ?? 0)
        let backTime = elapsedTime > videoSkipBackwardsDuration ? elapsedTime - videoSkipBackwardsDuration : 0.0
        playerControls?.updateTimeLabel(elapsedTime: backTime, duration: videoDuration)
        videoPlayer.seek(to: CMTimeMakeWithSeconds(backTime, 100)) { [weak self]
            (completed: Bool) -> Void in
            self?.videoPlayer.play()
        }
        
        if let videoId = video?.summary?.videoID, let courseId = video?.course_id, let unitUrl = video?.summary?.unitURL {
            OEXAnalytics.shared().trackVideoSeekRewind(videoId, requestedDuration:-videoSkipBackwardsDuration, oldTime:oldTime, newTime: self.currentTime, courseID: courseId, unitURL: unitUrl, skipType: "skip")
        }
    }
    
    func fullscreenPressed() {
        if (UIInterfaceOrientationIsPortrait(UIApplication.shared.statusBarOrientation)) {
            setFullscreen(fullscreen: !movieFullscreen, animated: true, with: UIInterfaceOrientation.landscapeLeft, forceRotate:true)
        }
        else {
            setFullscreen(fullscreen: !movieFullscreen, animated: true, with: UIInterfaceOrientation.landscapeLeft, forceRotate:false)
        }
    }
    
    func sliderValueChanged(playerControls: VideoPlayerControls) {
        let videoDuration = CMTimeGetSeconds(self.duration)
        let elapsedTime: Float64 = videoDuration * Float64(playerControls.durationSliderValue)
        playerControls.updateTimeLabel(elapsedTime: elapsedTime, duration: videoDuration)
    }
    
    func sliderTouchBegan(playerControls: VideoPlayerControls) {
        playerStartTime = self.currentTime
        videoPlayer.pause()
    }
    
    func sliderTouchEnded(playerControls: VideoPlayerControls) {
        let videoDuration = CMTimeGetSeconds(self.duration)
        let elapsedTime: Float64 = videoDuration * Float64(playerControls.durationSliderValue)
        playerControls.updateTimeLabel(elapsedTime: elapsedTime, duration: videoDuration)
        
        videoPlayer.seek(to: CMTimeMakeWithSeconds(elapsedTime, 100)) { [weak self]
            (completed: Bool) -> Void in
            if self?.playerState == .Playing {
                self?.videoPlayer.play()
            }
            else {
                self?.saveCurrentTime()
            }
        }
        
        playerStopTime = self.currentTime
        if let videoId = video?.summary?.videoID, let courseId = video?.course_id, let unitUrl = video?.summary?.unitURL {
            OEXAnalytics.shared().trackVideoSeekRewind(videoId, requestedDuration:playerStopTime - playerStartTime, oldTime:playerStartTime, newTime: playerStopTime, courseID: courseId, unitURL: unitUrl, skipType: "slide")
        }
    }
    
    func setPlayBackSpeed(playerControls: VideoPlayerControls, speed:OEXVideoSpeed) {
        let oldSpeed = self.rate
        let playbackRate = OEXInterface.getOEXVideoSpeed(speed)
        OEXInterface.setCCSelectedPlaybackSpeed(speed)
        self.rate = playbackRate
        
        if let videoId = video?.summary?.videoID, let courseId = video?.course_id, let unitUrl = video?.summary?.unitURL {
            OEXAnalytics.shared().trackVideoSpeed(videoId, currentTime: self.currentTime, courseID: courseId, unitURL: unitUrl, oldSpeed: String(format: "%.1f", oldSpeed), newSpeed: String.init(format: "%.1f", playbackRate))
        }
    }
}

class PlayerView: UIView {
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
    
    var player: AVPlayer? {
        get {
            return playerLayer.player
        }
        
        set {
            playerLayer.player = newValue
        }
    }
    
    var playerLayer: AVPlayerLayer {
        return layer as! AVPlayerLayer
    }
    
    override class var layerClass: AnyClass {
        return AVPlayerLayer.self
    }
    
    func addGesture(gesture: UIGestureRecognizer) {
        if let _ = gestureRecognizers?.contains(gesture) {
            removeGesture(gesture: gesture)
        }
        addGestureRecognizer(gesture)
    }
    
    func removeGesture(gesture: UIGestureRecognizer) {
        removeGestureRecognizer(gesture)
    }
    
}

extension AVPlayer {
    var isPlaying: Bool {
        return rate != 0 && error == nil
    }
}
