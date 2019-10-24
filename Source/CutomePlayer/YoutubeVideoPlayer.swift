//
//  YoutubeVideoPlayer.swift
//  edX
//
//  Created by Andrey on 9/4/18.
//  Copyright © 2018 edX. All rights reserved.
//

class YoutubeVideoPlayer: VideoPlayer {

    let playerView: WKYTPlayerView
    var videoID: String = ""
    private var videoCurrentTime: Float = 0.0
    let barTintColor: UIColor

    private struct playerVars {
        var playsinline = 0
        var start = 0
        var value: [String:Int] {
            get{
                return [
                    "playsinline": playsinline,
                    "autohide": 1,
                    "fs": 0,
                    "showinfo": 0,
                    "start": start
                ]
            }
        }
    }

    override var currentTime: TimeInterval {
        playerView.getCurrentTime({ [weak self] (time, nil) in
            self?.videoCurrentTime = time
        })
        return Double(videoCurrentTime)
    }
    override init(environment : Environment) {
        playerView = WKYTPlayerView()
        barTintColor = UINavigationBar.appearance().barTintColor ?? environment.styles.navigationItemTintColor()
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        playerView.stopVideo()
        UINavigationBar.appearance().barTintColor = barTintColor
    }

    private func createYoutubePlayer() {
        loadingIndicatorView.startAnimating()
        UINavigationBar.appearance().barTintColor = .black
        view.addSubview(playerView)
    }

    func setVideoPlayerMode(isPortrait: Bool) {
        let screenSize: CGRect = UIScreen.main.bounds

        if isPortrait {
            playerView.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.width * CGFloat(STANDARD_VIDEO_ASPECT_RATIO))
        }
        else {
            playerView.frame = CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height)
        }
    }

    override func play(video: OEXHelperVideoDownload) {
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
    }

    override func setFullscreen(fullscreen: Bool, animated: Bool, with deviceOrientation: UIInterfaceOrientation, forceRotate rotate: Bool) {
        isFullScreen = fullscreen
        let playerVars = YoutubeVideoPlayer.playerVars(playsinline: Int(truncating: NSNumber(value:!fullscreen)), start: Int(currentTime))

        playerView.load(withVideoId: videoID, playerVars: playerVars.value)
        setVideoPlayerMode(isPortrait: !fullscreen)
        
        if let courseId = video?.course_id, let unitUrl = video?.summary?.unitURL {
            environment.analytics.trackVideoOrientation(videoID, courseID: courseId, currentTime: CGFloat(currentTime), mode: fullscreen, unitURL: unitUrl, playMedium: value_play_medium_youtube)
        }
    }

    override func seek(to time: Double) {
        playerView.seek(toSeconds: Float(time), allowSeekAhead: true)
    }
    
    private func showErrorMessage(message : String) {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .center
        
        view.addSubview(label)
        
        let textStyle = OEXTextStyle(weight: .normal, size: .base, color: OEXStyles.shared().neutralWhite())
        label.attributedText = textStyle.attributedString(withText: message)
        
        label.snp.remakeConstraints { (make) in
            make.centerX.equalTo(view)
            make.centerY.equalTo(view)
        }

        loadingIndicatorView.stopAnimating()
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
            environment.interface?.sendAnalyticsEvents(.pause, withCurrentTime: currentTime, forVideo: video, playMedium: value_play_medium_youtube)
            break
        case .playing:
            environment.interface?.sendAnalyticsEvents(.play, withCurrentTime: currentTime, forVideo: video, playMedium: value_play_medium_youtube)
            break
        default:
            break
        }
    }

}
