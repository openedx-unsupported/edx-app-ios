//
//  YoutubeVideoPlayer.swift
//  edX
//
//  Created by Andrey on 9/4/18.
//  Copyright © 2018 edX. All rights reserved.
//

class YoutubeVideoPlayer: VideoPlayer {

    let playerView: WKYTPlayerView
    var videoId: String
    private var videoCurrentTime: Float
    private let background: UIColor
    
    private struct playVars {
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
        playerView.getCurrentTime({ (time, nil) in
            self.videoCurrentTime = time
        })
        return Double(videoCurrentTime)
    }
    override init(environment : Environment) {
        playerView = WKYTPlayerView()
        videoId = String()
        videoCurrentTime = Float()
        background = environment.styles.neutralWhite()
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
        UINavigationBar.appearance().barTintColor = background
    }

    private func createYoutubePlayer() {
        loadingIndicatorView.startAnimating()
        UINavigationBar.appearance().barTintColor = .black
        view.addSubview(playerView)
        t_captionLanguage = String(Locale.preferredLanguages[0].prefix(2))
    }

    func setVideoPlayerMode(portraitView: Bool) {
        let screenSize: CGRect = UIScreen.main.bounds

        if portraitView {
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
            return
        }

        let playvars = playVars(playsinline: 1, start: 0)
        guard let id = url.queryItems?.first?.value else {
            return
        }
        videoId = id
        playerView.load(withVideoId: videoId, playerVars: playvars.value)
    }

    override func setFullscreen(fullscreen: Bool, animated: Bool, with deviceOrientation: UIInterfaceOrientation, forceRotate rotate: Bool) {
        isFullScreen = fullscreen
        let playvars = playVars(playsinline: Int(truncating: NSNumber(value:!fullscreen)), start: Int(currentTime))

        playerView.load(withVideoId: videoId, playerVars: playvars.value)
        setVideoPlayerMode(portraitView: !fullscreen)

    }

    override func seek(to time: Double) {
        playerView.seek(toSeconds: Float(time), allowSeekAhead: true)
    }
 }

extension YoutubeVideoPlayer: WKYTPlayerViewDelegate {

    func playerViewDidBecomeReady(_ playerView: WKYTPlayerView) {
        // call play video when the player is finished loading.
        setVideoPlayerMode(portraitView: UIDevice.current.orientation.isPortrait)
        loadingIndicatorView.stopAnimating()
        playerView.playVideo()
    }

}
