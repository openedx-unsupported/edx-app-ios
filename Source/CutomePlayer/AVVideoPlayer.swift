//
//  AVVideoPlayer.swift
//  edX
//
//  Created by Salman on 05/03/2018.
//  Copyright © 2018 edX. All rights reserved.
//

import UIKit
import AVKit

protocol VideoPlayerControllerDelegate {
    func transcriptLoaded(transcripts: [SubTitle])
    func moviePlayerWillMoveFromWindow()
    func playerDidStopPlaying(duration: Double, currentTime: Double)
    func movieTimedOut()
    func didFinishVideoPlaying()
}

private var playbackLikelyToKeepUpContext = 0
@objc class AVVideoPlayer: UIViewController,VideoPlayerControlsDelegate,VideoSubTitleDelegate {
    
    var contentURL : URL?
    let videoPlayer = AVPlayer()
    var playerControls: AVVideoPlayerControls?
    let loadingIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: .white)
    var lastElapsedTime: TimeInterval = 0
    var playerDelegate : VideoPlayerControllerDelegate?
    var movieFullscreen : Bool = false
    var timeObserver : AnyObject?
    let playerView = PlayerView()
    var height: Double = 0
    var width: Double = 0
    var defaultFrame : CGRect = CGRect.zero
    var videoSubTitle: VideoSubTitle?
    let videoSkipBackwardsDuration: Double = 30
    
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
        view.backgroundColor = .black
        createPlayer()
        loadingIndicatorView.hidesWhenStopped = true
        addObservers()
    }
    
    func addObservers() {
        videoPlayer.addObserver(self, forKeyPath: "currentItem.playbackLikelyToKeepUp",
                                options: .new, context: &playbackLikelyToKeepUpContext)
        
        videoPlayer.addObserver(self, forKeyPath: "currentItem.status",
                                options: .new, context: nil)
        
        NotificationCenter.default.addObserver(self, selector:#selector(playerDidFinishPlaying(note:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: videoPlayer.currentItem)
        
        let timeInterval: CMTime = CMTimeMakeWithSeconds(1.0, 10)
        timeObserver = videoPlayer.addPeriodicTimeObserver(forInterval: timeInterval, queue: DispatchQueue.main) { [weak self]
            (elapsedTime: CMTime) -> Void in
            self?.observeTime(elapsedTime: elapsedTime)
            } as AnyObject
    }
    
    private func observeTime(elapsedTime: CMTime) {
        let duration = CMTimeGetSeconds(self.duration)
        if duration.isFinite {
            let elapsedTime = CMTimeGetSeconds(elapsedTime)
            playerControls?.durationSlider.value = Float(elapsedTime / duration)
            playerControls?.updateTimeLabel(elapsedTime: elapsedTime, duration: duration)
        }
    }
    
    func createPlayer() {
        view.addSubview(playerView)
        playerView.playerLayer.player = videoPlayer
        view.layer.insertSublayer(playerView.playerLayer, at: 0)
        let controls = AVVideoPlayerControls(with: self)
        controls.delegate = self
        playerControls = controls
        playerView.addSubview(controls)
        playerView.addSubview(loadingIndicatorView)
        
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback, with: [])
        setControlsConstraints()
    }
    
    func initializeSubtitles() {
        if let video = video {
            videoSubTitle = VideoSubTitle(with: video)
            videoSubTitle?.delegate = self
            videoSubTitle?.initializeSubtitle()
            
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
                    playerControls?.tapButton.isHidden = false
                    break
                case .unknown:
                    playerControls?.tapButton.isHidden = true
                    break
                case .failed:
                    playerControls?.tapButton.isHidden = true
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
    
    func checkForOrientation() {
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
        playerControls?.tapButton.isHidden = true
        perform(#selector(movieTimedOut), with: nil, afterDelay: 60)
    }
    
    func movieTimedOut() {
        stop()
        playerDelegate?.movieTimedOut()
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
        lastElapsedTime = currentTime
        playerDelegate?.playerDidStopPlaying(duration: duration.seconds, currentTime: currentTime)
    }
    
    func stop() {
        playerDelegate?.playerDidStopPlaying(duration: duration.seconds, currentTime: currentTime)
        videoPlayer.actionAtItemEnd = AVPlayerActionAtItemEnd.pause
        videoPlayer.replaceCurrentItem(with: nil)
    }
    
    func removeObservers() {
        if let observer = timeObserver {
            videoPlayer.removeTimeObserver(observer)
            timeObserver = nil
        }
        videoPlayer.removeObserver(self, forKeyPath: "currentItem.playbackLikelyToKeepUp")
        videoPlayer.removeObserver(self, forKeyPath: "currentItem.status")
        NotificationCenter.default.removeObserver(self)
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
    
    func resetView() {
        movieBackgroundView.removeFromSuperview()
        if !(view.subviews.contains(playerView)) {
            view.addSubview(playerView)
            view.frame = defaultFrame
            playerControls?.removeGesters()
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
                playerControls?.addGesters()
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
    
    func subTitleLoaded(transcripts: [SubTitle]) {
        playerDelegate?.transcriptLoaded(transcripts: transcripts)
    }
    
    func playerDidFinishPlaying(note: NSNotification) {
        playerDelegate?.didFinishVideoPlaying()
    }
    
    func playPausePressed(isPlaying: Bool) {
        if videoPlayer.isPlaying {
            pause()
            OEXInterface.shared().sendAnalyticsEvents(.pause, withCurrentTime: self.currentTime, forVideo: video)
        }
        else {
            resume()
            OEXInterface.shared().sendAnalyticsEvents(.play, withCurrentTime: self.currentTime, forVideo: video)
        }
    }
    
    func seekBackwardPressed() {
        let oldTime = self.currentTime
        let videoDuration = CMTimeGetSeconds(self.duration)
        let elapsedTime: Float64 = videoDuration * Float64(playerControls?.durationSlider.value ?? 0)
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
}

class PlayerView: UIView {
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
}

extension AVPlayer {
    var isPlaying: Bool {
        return rate != 0 && error == nil
    }
}
