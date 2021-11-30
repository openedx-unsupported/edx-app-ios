//
//  YoutubeVideoPlayer.swift
//  edX
//
//  Created by Andrey on 9/4/18.
//  Copyright © 2018 edX. All rights reserved.
//

private let playerTimeOutInterval = 60.0

class YoutubeVideoPlayer: VideoPlayer {

    let playerView: WKYTPlayerView
    var videoID: String = ""
    private var videoCurrentTime: Float = 0.0
    var viewHeightOffset: CGFloat = 90

    private lazy var errorMessageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.textColor = .white
        label.textAlignment = .center

        return label
    }()

    private struct playerVars {
        var playsinline = 0
        var start = 0
        var value: [String:Int] {
            get {
                return [
                    "controls": 1,
                    "playsinline": playsinline,
                    "autohide": 1,
                    "fs": 1,
                    "showinfo": 0,
                    "modestbranding": 1,
                    "start": start
                ]
            }
        }
    }

    override var currentTime: TimeInterval {
        playerView.getCurrentTime { [weak self] time, _ in
            self?.videoCurrentTime = time
        }
        return Double(videoCurrentTime)
    }
    
    override init(environment : Environment) {
        playerView = WKYTPlayerView()
        super.init(environment: environment)
        playerView.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        createYoutubePlayer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UINavigationBar.appearance().barTintColor = .black
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        playerView.stopVideo()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        UINavigationBar.appearance().barTintColor = environment.styles.navigationBarColor()
    }

    private func createYoutubePlayer() {
        loadingIndicatorView.startAnimating()
        view.addSubview(playerView)
    }

    func setVideoPlayerMode(isPortrait: Bool) {
        let screenSize: CGRect = UIScreen.main.bounds

        if isPortrait {
            playerView.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.width * CGFloat(STANDARD_VIDEO_ASPECT_RATIO))
        }
        else {
            let widthOffset: CGFloat = UIDevice.current.hasNotch ? 88 : 0
            if isiPad() {
                //Ideally the heightOffset should be the size of toolbar but with frame it's not working properly
                // And required more height as offset to display the youtube player controls
                viewHeightOffset = 120
            }
            playerView.frame = CGRect(x: 0, y: 0, width: screenSize.width - widthOffset, height: screenSize.height - viewHeightOffset)
        }
    }

    override func play(video: OEXHelperVideoDownload, time: TimeInterval? = nil) {
        super.setVideo(video: video)
        guard let videoUrl = video.summary?.videoURL, let url = URLComponents(string : videoUrl) else {
            Logger.logError("YOUTUBE_VIDEO", "invalid url")
            showErrorMessage(message: Strings.youtubeInvalidUrlError)
            return
        }

        let playerVars = YoutubeVideoPlayer.playerVars(playsinline: 1, start: 0)
        guard let videoID = url.queryItems?.first?.value else {
            Logger.logError("YOUTUBE_VIDEO", "invalid video ID")
            showErrorMessage(message: Strings.youtubeInvalidUrlError)
            return
        }
        self.videoID = videoID
        playerView.load(withVideoId: videoID, playerVars: playerVars.value)

        if view.subviews.contains(errorMessageLabel){
            removeErrorMessage()
        }
        perform(#selector(videoTimedOut), with: nil, afterDelay: playerTimeOutInterval)
    }
    
    override func pause() {
        playerView.stopVideo()
    }

    override func setFullscreen(fullscreen: Bool, animated: Bool, with deviceOrientation: UIInterfaceOrientation, forceRotate rotate: Bool) {
        isFullScreen = fullscreen
        let playerVars = YoutubeVideoPlayer.playerVars(playsinline: Int(truncating: NSNumber(value:!fullscreen)), start: Int(currentTime))

        playerView.load(withVideoId: videoID, playerVars: playerVars.value)
        setVideoPlayerMode(isPortrait: !fullscreen)
        
        if let courseId = video?.course_id, let unitUrl = video?.summary?.unitURL {
            environment.analytics.trackVideoOrientation(videoID, courseID: courseId, currentTime: CGFloat(currentTime), mode: fullscreen, unitURL: unitUrl, playMedium: AnalyticsEventDataKey.PlayMediumYoutube.rawValue)
        }
    }

    override func seek(to time: Double, completion: ((Bool)->())? = nil) {
        playerView.seek(toSeconds: Float(time), allowSeekAhead: true)
        completion?(true)
    }
    
    private func showErrorMessage(message : String) {

        if !view.subviews.contains(errorMessageLabel) {
            view.addSubview(errorMessageLabel)
        }
        
        let textStyle = OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().neutralWhite())
        errorMessageLabel.attributedText = textStyle.attributedString(withText: message)
        
        errorMessageLabel.snp.remakeConstraints { (make) in
            make.centerX.equalTo(view)
            make.centerY.equalTo(view)
        }

        loadingIndicatorView.stopAnimating()
    }

    private func removeErrorMessage() {
        errorMessageLabel.attributedText = nil
        errorMessageLabel.removeFromSuperview()
    }

    @objc private func videoTimedOut() {
        playerView.stopVideo()
        showErrorMessage(message: Strings.timeoutCheckInternetConnection)
    }
 }

extension YoutubeVideoPlayer: WKYTPlayerViewDelegate {

    func playerViewDidBecomeReady(_ playerView: WKYTPlayerView) {
        // call play video when the player is finished loading.
        setVideoPlayerMode(isPortrait: UIDevice.current.orientation.isPortrait)
        loadingIndicatorView.stopAnimating()
        playerView.playVideo()
    }

    func playerView(_ playerView: WKYTPlayerView, didChangeTo state: WKYTPlayerState) {
        switch state {
        case .paused:
            environment.interface?.sendAnalyticsEvents(.pause, withCurrentTime: currentTime, forVideo: video, playMedium: AnalyticsEventDataKey.PlayMediumYoutube.rawValue)
            break
        case .playing:
            environment.interface?.sendAnalyticsEvents(.play, withCurrentTime: currentTime, forVideo: video, playMedium: AnalyticsEventDataKey.PlayMediumYoutube.rawValue)
            NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(videoTimedOut), object: nil)
            break
        case .ended:
             playerDelegate?.playerDidFinishPlaying(videoPlayer: self)
            break
        default:
            break
        }
    }

}

extension UIDevice {
    var hasNotch: Bool {
        return UIApplication.shared.keyWindow?.safeAreaInsets.bottom ?? 0 > 0
    }
}
